// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'converter.dart';
import 'detector.dart' as detector;

/// Signature for the "has this file stopped changing?" probe. Injectable so
/// tests can drive the debounce deterministically without touching the clock.
typedef SizeProbe = int? Function(String path);

/// Signature for a wait between debounce polls. Injectable for tests.
typedef Sleeper = Future<void> Function(Duration duration);

/// Watches a folder and converts each supported ROM that lands in it.
///
/// A file is only handed to the converter once its size has been stable for
/// [settleSeconds]; this avoids racing a still-downloading file. Files that
/// are already converting (or that have been seen) are never queued twice.
class WatchFolderDaemon {
  final String inputDir;
  final String outputDir;
  final String targetFormat;
  final String compression;
  final bool verify;
  final bool deleteSource;
  final String audioCodec;

  /// Seconds a file's size must remain unchanged before conversion starts.
  final int settleSeconds;

  final void Function(String message)? onLog;
  final void Function(String file, double pct)? onProgress;
  final void Function(String file, bool success, String? error)? onDone;

  final Converter converter;
  final SizeProbe _sizeProbe;
  final Sleeper _sleep;

  /// Milliseconds between stability checks while a file is settling.
  final Duration pollInterval;

  final Set<String> _seen = <String>{};
  final Set<String> _inFlight = <String>{};
  StreamSubscription<FileSystemEvent>? _sub;
  bool _stopped = false;

  WatchFolderDaemon({
    required this.inputDir,
    required this.outputDir,
    this.targetFormat = 'CHD',
    this.compression = 'Normal',
    this.verify = false,
    this.deleteSource = false,
    this.audioCodec = 'flac',
    this.settleSeconds = 3,
    this.onLog,
    this.onProgress,
    this.onDone,
    Converter? converter,
    SizeProbe? sizeProbe,
    Sleeper? sleeper,
    this.pollInterval = const Duration(milliseconds: 500),
  })  : _sizeProbe = sizeProbe ?? _defaultSizeProbe,
        _sleep = sleeper ?? Future<void>.delayed,
        converter = converter ??
            Converter(
              onLogCb: (msg) => onLog?.call(msg),
              onProgress: (job, pct) =>
                  onProgress?.call(p.basename(job.filepath), pct),
            );

  static int? _defaultSizeProbe(String path) {
    try {
      final f = File(path);
      return f.existsSync() ? f.lengthSync() : null;
    } catch (_) {
      return null;
    }
  }

  bool get isRunning => !_stopped;

  /// Waits until [path]'s size is unchanged across a [settleSeconds] window.
  ///
  /// Returns the settled size, or null when the file vanished. A file that
  /// never stops growing keeps the loop alive until it stabilises (or [stop]).
  Future<int?> awaitStable(String path) async {
    final intervalMs =
        pollInterval.inMilliseconds <= 0 ? 1 : pollInterval.inMilliseconds;
    final requiredStableChecks =
        (settleSeconds * 1000 / intervalMs).ceil().clamp(1, 1 << 30);

    int? lastSize;
    int stableChecks = 0;
    while (!_stopped) {
      final size = _sizeProbe(path);
      if (size == null) return null;
      if (size == lastSize) {
        stableChecks++;
        if (stableChecks >= requiredStableChecks) return size;
      } else {
        lastSize = size;
        stableChecks = 0;
      }
      await _sleep(pollInterval);
    }
    return null;
  }

  /// Runs [path] through the pipeline once it has settled. Public so tests can
  /// invoke the full flow without a real [Directory.watch] event stream.
  Future<bool> handleFile(String path) async {
    final name = p.basename(path);
    if (_seen.contains(path) || _inFlight.contains(path)) return false;

    final ext = detector.getExtension(name);
    final normalized = ext.startsWith('.') ? ext : '.$ext';
    if (!detector.supportedInput.containsKey(normalized)) {
      _log('[SKIP] Unsupported format: $name');
      return false;
    }

    // Skip the daemon's own outputs landing in a watched input folder.
    if (p.dirname(p.canonicalize(path)) == p.canonicalize(outputDir)) {
      _log('[SKIP] File is in the output folder: $name');
      return false;
    }

    _inFlight.add(path);
    _log('[WAIT] $name — waiting for writes to settle…');
    try {
      final size = await awaitStable(path);
      if (size == null) {
        _log('[SKIP] $name disappeared before it settled.');
        return false;
      }

      _log('[NEW] $name ($size bytes) — converting to $targetFormat');
      final job = ConversionJob(
        filepath: path,
        outputDir: outputDir,
        targetFormat: targetFormat,
        compression: compression,
        verify: verify,
        audioCodec: audioCodec,
      );

      final ok = await converter.convert(job);
      _seen.add(path);

      if (ok && deleteSource) {
        try {
          final src = File(path);
          if (src.existsSync()) {
            src.deleteSync();
            _log('[DELETE] Removed source: $name');
          }
        } catch (e) {
          _log('[WARN] Could not delete source: $e');
        }
      }

      onDone?.call(path, ok, job.error);
      return ok;
    } finally {
      _inFlight.remove(path);
    }
  }

  /// Processes every supported file already present in [inputDir].
  Future<void> sweepExisting() async {
    final dir = Directory(inputDir);
    if (!dir.existsSync()) return;
    for (final entry in dir.listSync()) {
      if (_stopped) return;
      if (entry is File) {
        await handleFile(entry.path);
      }
    }
  }

  /// Starts watching. Resolves when [stop] is called (or the stream closes).
  Future<void> start() async {
    final dir = Directory(inputDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    Directory(outputDir).createSync(recursive: true);

    _log('[WATCH] Watching ${dir.path} → $outputDir ($targetFormat)');
    await sweepExisting();

    if (_stopped) return;
    final completer = Completer<void>();
    _sub = dir.watch().listen(
          (event) {
            if (_stopped) return;
            final path = event.path;
            if (event is FileSystemCreateEvent ||
                event is FileSystemModifyEvent) {
              // Creation/modify events fire repeatedly while a file is written;
              // handleFile's settle loop + _inFlight guard dedupe them.
              unawaited(handleFile(path));
            }
          },
          onError: (Object e) => _log('[WARN] Watch error: $e'),
          onDone: () {
            if (!completer.isCompleted) completer.complete();
          },
        );
    await completer.future;
  }

  Future<void> stop() async {
    _stopped = true;
    await _sub?.cancel();
    _sub = null;
  }

  void _log(String msg) {
    if (onLog != null) {
      onLog!(msg);
    } else {
      print(msg);
    }
  }
}
