// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

import 'seven_zip.dart';

const Set<String> excludedExtensions = {
  '.chd',
  '.cso',
  '.rvz',
  '.7z',
  '.zip',
  '.gz',
  '.zst',
  '.csz',
  '.zso',
};

class CompressionJob {
  final String filepath;
  final String outputDir;
  final String format; // "zip" | "extract" | "7z"
  final String level; // "fast" | "normal" | "ultra"
  final bool deleteSource;
  String status; // Queued|Compressing|Extracting|Done|Failed
  double progress;
  String? error;

  CompressionJob({
    required this.filepath,
    required this.outputDir,
    String format = 'zip',
    String level = 'normal',
    this.deleteSource = false,
    this.status = 'Queued',
    this.progress = 0.0,
    this.error,
  })  : format = format.toLowerCase(),
        level = level.toLowerCase();
}

class Compressor {
  final void Function(String msg)? onLog;
  final void Function(CompressionJob job, double pct)? onProgress;
  final SevenZip? _injectedSevenZip;
  SevenZip? _resolvedSevenZip;
  bool _stopped = false;

  Compressor({this.onLog, this.onProgress, SevenZip? sevenZip})
      : _injectedSevenZip = sevenZip;

  /// The 7-Zip wrapper to use, located lazily on first need.
  SevenZip? get _sevenZip {
    if (_injectedSevenZip != null) return _injectedSevenZip;
    return _resolvedSevenZip ??= _locateSevenZip();
  }

  SevenZip? _locateSevenZip() {
    final exe = SevenZip.locate(onLog: _log);
    if (exe == null) {
      _log('[7Z] No 7-Zip executable found (looked for 7zz/7z/7za/7zr and '
          'OPENROM_7Z).');
      return null;
    }
    return SevenZip(exe, onLog: _log);
  }

  void stop() {
    _stopped = true;
  }

  void _log(String msg) {
    if (onLog != null) {
      try {
        onLog!(msg);
      } catch (_) {}
    }
  }

  void _updateProgress(CompressionJob job, double pct) {
    job.progress = pct.clamp(0.0, 100.0);
    if (onProgress != null) {
      try {
        onProgress!(job, job.progress);
      } catch (_) {}
    }
  }

  bool isAlreadyCompressed(String filepath) {
    final ext = p.extension(filepath).toLowerCase();
    return excludedExtensions.contains(ext);
  }

  bool compress(CompressionJob job) {
    _stopped = false;

    if (job.format == 'extract') {
      return extract(job);
    }

    if (!File(job.filepath).existsSync() &&
        !Directory(job.filepath).existsSync()) {
      job.status = 'Failed';
      job.error = 'File or directory not found: ${job.filepath}';
      _log('[ERROR] ${job.error}');
      return false;
    }

    if (isAlreadyCompressed(job.filepath)) {
      job.status = 'Done';
      job.progress = 100.0;
      job.error = 'Skipped (already compressed)';
      _log(
        '[SKIP] ${p.basename(job.filepath)} is already compressed. Skipped.',
      );
      _updateProgress(job, 100.0);
      return true;
    }

    final is7z = job.format == '7z' || job.format == '.7z';

    job.status = 'Compressing';
    _updateProgress(job, 0.0);
    Directory(job.outputDir).createSync(recursive: true);

    try {
      final success = is7z ? _compress7z(job) : _compressZip(job);
      if (success) {
        job.status = 'Done';
        job.progress = 100.0;
        _updateProgress(job, 100.0);
        if (job.deleteSource) {
          _deleteSourcePath(job.filepath);
        }
        return true;
      } else {
        job.status = 'Failed';
        return false;
      }
    } catch (e) {
      job.status = 'Failed';
      job.error = e.toString();
      _log('[ERROR] Compression failed: $e');
      return false;
    }
  }

  bool extract(CompressionJob job) {
    _stopped = false;

    if (!File(job.filepath).existsSync()) {
      job.status = 'Failed';
      job.error = 'Archive file not found: ${job.filepath}';
      _log('[ERROR] ${job.error}');
      return false;
    }

    final is7z = p.extension(job.filepath).toLowerCase() == '.7z';

    job.status = 'Extracting';
    _updateProgress(job, 0.0);
    Directory(job.outputDir).createSync(recursive: true);

    try {
      final success = is7z ? _extract7z(job) : _extractZip(job);
      if (success) {
        job.status = 'Done';
        job.progress = 100.0;
        _updateProgress(job, 100.0);
        if (job.deleteSource) {
          _deleteSourcePath(job.filepath);
        }
        return true;
      } else {
        job.status = 'Failed';
        return false;
      }
    } catch (e) {
      job.status = 'Failed';
      job.error = e.toString();
      _log('[ERROR] Extraction failed: $e');
      return false;
    }
  }

  /// 7z compression via the external 7-Zip binary.
  ///
  /// `Process.runSync` cannot stream, so progress only moves 0 -> 100 around
  /// the single blocking invocation rather than tracking the archive as it is
  /// written. (Documented limitation; a streamed variant is a later task.)
  bool _compress7z(CompressionJob job) {
    final sevenZip = _sevenZip;
    if (sevenZip == null) {
      job.error = sevenZipNotFoundMessage;
      _log('[ERROR] ${job.error}');
      return false;
    }

    final baseName = p.basename(job.filepath);
    _log('[7Z] Compressing $baseName -> ${baseName}.7z (level ${job.level})');

    final error = sevenZip.compress(
      source: job.filepath,
      outputDir: job.outputDir,
      level: job.level,
    );

    if (error != null) {
      job.error = error;
      _log('[ERROR] $error');
      return false;
    }

    _updateProgress(job, 100.0);
    return true;
  }

  /// 7z extraction via the external 7-Zip binary.
  bool _extract7z(CompressionJob job) {
    final sevenZip = _sevenZip;
    if (sevenZip == null) {
      job.error = sevenZipNotFoundMessage;
      _log('[ERROR] ${job.error}');
      return false;
    }

    _log(
      '[7Z] Extracting ${p.basename(job.filepath)} -> ${job.outputDir}',
    );

    final error = sevenZip.extract(
      archive: job.filepath,
      outputDir: job.outputDir,
    );

    if (error != null) {
      job.error = error;
      _log('[ERROR] $error');
      return false;
    }

    _updateProgress(job, 100.0);
    return true;
  }

  bool _compressZip(CompressionJob job) {
    final baseName = p.basenameWithoutExtension(job.filepath);
    final outPath = p.join(job.outputDir, '$baseName.zip');
    _log(
      '[ZIP] Compressing ${p.basename(job.filepath)} → ${p.basename(outPath)}',
    );

    final encoder = ZipFileEncoder();
    encoder.create(outPath);

    if (File(job.filepath).existsSync()) {
      encoder.addFile(File(job.filepath));
      _updateProgress(job, 50.0);
    } else if (Directory(job.filepath).existsSync()) {
      encoder.addDirectory(Directory(job.filepath));
      _updateProgress(job, 50.0);
    }

    encoder.close();
    _updateProgress(job, 100.0);
    return true;
  }

  bool _extractZip(CompressionJob job) {
    _log('[UNZIP] Extracting ${p.basename(job.filepath)} → ${job.outputDir}');

    final inputStream = InputFileStream(job.filepath);
    try {
      final archive = ZipDecoder().decodeBuffer(inputStream);

      final total = archive.length == 0 ? 1 : archive.length;
      final basePath = p.normalize(p.canonicalize(job.outputDir));

      for (int i = 0; i < archive.length; i++) {
        if (_stopped) return false;
        final file = archive[i];
        final destPath = p.normalize(p.join(basePath, file.name));

        // Zip-Slip security check
        if (!destPath.startsWith(basePath + p.separator) &&
            destPath != basePath) {
          throw FormatException(
            'Malicious archive entry (Zip Slip): ${file.name}',
          );
        }

        if (file.isFile) {
          final parentDir = Directory(p.dirname(destPath));
          if (!parentDir.existsSync()) {
            parentDir.createSync(recursive: true);
          }
          final outputStream = OutputFileStream(destPath);
          try {
            file.writeContent(outputStream);
          } finally {
            outputStream.close();
          }
        } else {
          Directory(destPath).createSync(recursive: true);
        }

        final pct = ((i + 1) / total) * 100.0;
        _updateProgress(job, pct);
      }
    } finally {
      inputStream.close();
    }

    return true;
  }

  void _deleteSourcePath(String filepath) {
    try {
      if (File(filepath).existsSync()) {
        File(filepath).deleteSync();
        _log('[CLEANUP] Deleted source file: $filepath');
      } else if (Directory(filepath).existsSync()) {
        Directory(filepath).deleteSync(recursive: true);
        _log('[CLEANUP] Deleted source directory: $filepath');
      }
    } catch (e) {
      _log('[WARN] Failed to delete source $filepath: $e');
    }
  }
}
