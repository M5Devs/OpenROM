// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'config.dart' as config;
import 'cue_generator.dart';
import 'detector.dart' as detector;
import 'logger.dart' as logger;
import 'plugin/plugin_manager.dart';
import 'plugin/plugin_registry.dart';
import 'validator.dart';

const List<String> cdPlatforms = [
  'PS1',
  'Dreamcast',
  'Saturn',
  'Sega CD',
  'PC-Engine CD',
  'Neo Geo CD',
  'CD',
  '3DO',
  'CD-i',
];

const List<String> dvdPlatforms = [
  'PS2',
  'Xbox',
  'Xbox 360',
  'PSP',
  'GameCube',
  'Wii',
  'Wii U',
  'DVD',
];

const Map<String, String> chdCdCompression = {
  'Normal': 'cdlz',
  'High': 'cdzs,cdlz',
  'Max': 'cdlz,cdzs,flac',
};

const Map<String, String> chdDvdCompression = {
  'Normal': 'zlib',
  'High': 'zstd,zlib,huff',
  'Max': 'zstd,zlib,huff,flac',
};

/// The set of `FROM->TO` routes the built-in engine handles natively. Used to
/// enforce plugin route precedence: a plugin may not shadow any of these
/// unless it declared `"override": true`.
final Set<String> builtinRoutes = {
  for (final entry in detector.builtinConversionMap.entries)
    for (final to in entry.value) '${entry.key}->${to.toUpperCase()}',
};

/// Formats that OpenROM Core no longer bundles a tool for. They are handled by
/// community `.orplug` extensions from the OpenROM Extension Store; when no
/// such extension is installed the converter returns [communityExtensionError]
/// instead of failing on a missing binary.
const Set<String> communityExtensionFormats = {
  'XISO',
  'CCI',
  'ZAR',
  'WUD',
  'WUX',
  'WUA',
  'NKIT',
};

const String communityExtensionError =
    'Format requires a community extension (e.g. NKit or Xbox Suite). '
    'Please install it from the OpenROM Extension Store.';

/// True when [fmt] or [tgt] belongs to a decoupled format family.
bool requiresCommunityExtension(String fmt, String tgt) =>
    communityExtensionFormats.contains(fmt.toUpperCase()) ||
    communityExtensionFormats.contains(tgt.toUpperCase());

/// Basenames of the tools that were decoupled in v4.0.0, including the
/// Windows/legacy spellings. Used by [_Converter._run] as a last-resort guard.
const Set<String> decoupledToolNames = {
  'nkit',
  'nkit.exe',
  'saturn-patcher',
  'saturn-patcher.exe',
  'xgdtool',
  'XGDTool',
  'XGDTool.exe',
  'extract-xiso',
  'extract-xiso.exe',
};

List<String> cleanCommandArgs(List<String> args) {
  return args.map((arg) {
    var a = arg.trim();
    if ((a.startsWith('"') && a.endsWith('"')) ||
        (a.startsWith("'") && a.endsWith("'"))) {
      if (a.length >= 2) {
        a = a.substring(1, a.length - 1);
      }
    }
    return a;
  }).toList();
}

List<String> splitCommandArgs(String cmdLine) {
  final List<String> result = [];
  final StringBuffer current = StringBuffer();
  bool inDoubleQuotes = false;
  bool inSingleQuotes = false;

  for (int i = 0; i < cmdLine.length; i++) {
    final char = cmdLine[i];
    if (char == '"' && !inSingleQuotes) {
      inDoubleQuotes = !inDoubleQuotes;
    } else if (char == "'" && !inDoubleQuotes) {
      inSingleQuotes = !inSingleQuotes;
    } else if (char == ' ' && !inDoubleQuotes && !inSingleQuotes) {
      if (current.isNotEmpty) {
        result.add(current.toString());
        current.clear();
      }
    } else {
      current.write(char);
    }
  }
  if (current.isNotEmpty) {
    result.add(current.toString());
  }

  return cleanCommandArgs(result);
}

Future<void> processStreamLines(
  Stream<List<int>> stream,
  void Function(String line) onLine,
) async {
  String buffer = '';
  await for (final chunk in stream.transform(utf8.decoder)) {
    buffer += chunk;
    final parts = buffer.split(RegExp(r'[\r\n]+'));
    for (int i = 0; i < parts.length - 1; i++) {
      onLine(parts[i]);
    }
    buffer = parts.last;
  }
  if (buffer.isNotEmpty) {
    onLine(buffer);
  }
}

class ConversionJob {
  final String filepath;
  final String outputDir;
  String targetFormat;
  final String compression;
  final bool verify;
  final String? forcePlatform;
  final String? media;
  final String? audioCodec;
  String status;
  double progress;
  final List<String> logLines;
  String? error;
  final List<String> tempFiles;
  Map<String, dynamic>? _fileInfo;

  /// Size of the primary input file, captured when the job starts.
  int originalSizeBytes = 0;

  /// Total size of the files this job produced, measured after success.
  int outputSizeBytes = 0;

  /// Absolute paths of every file the conversion is expected to write. Used to
  /// measure [outputSizeBytes] without re-deriving the route's naming rules.
  final List<String> outputPaths;

  ConversionJob({
    required this.filepath,
    required this.outputDir,
    required this.targetFormat,
    this.compression = 'Normal',
    this.verify = false,
    this.forcePlatform,
    this.media,
    this.audioCodec,
    this.status = 'Queued',
    this.progress = 0.0,
    List<String>? logLines,
    this.error,
    List<String>? tempFiles,
    List<String>? outputPaths,
  })  : logLines = logLines ?? [],
        tempFiles = tempFiles ?? [],
        outputPaths = outputPaths ?? [];

  /// Registers a file the conversion is expected to create.
  void addOutput(String path) {
    if (!outputPaths.contains(path)) outputPaths.add(path);
  }

  Map<String, dynamic> getFileInfo() {
    if (_fileInfo == null) {
      _fileInfo = detector.detectFile(filepath);
      if (forcePlatform != null && forcePlatform!.trim().isNotEmpty) {
        _fileInfo!['platform'] = forcePlatform!.trim();
      }
    }
    return _fileInfo!;
  }
}

/// Aggregate size statistics for a completed conversion batch. Byte figures
/// sum only successful jobs; [bytesSaved] may be negative when the outputs are
/// larger than the inputs (e.g. decompressing CHD → ISO).
class BatchStats {
  final int jobsCompleted;
  final int totalOriginalBytes;
  final int totalOutputBytes;

  const BatchStats({
    required this.jobsCompleted,
    required this.totalOriginalBytes,
    required this.totalOutputBytes,
  });

  int get bytesSaved => totalOriginalBytes - totalOutputBytes;

  /// Percentage of the input size reclaimed, or 0 when there is no input.
  double get savedPercentage =>
      totalOriginalBytes <= 0 ? 0.0 : (bytesSaved / totalOriginalBytes) * 100.0;

  String get bytesSavedReadable => detector.humanBytes(bytesSaved);

  /// One-decimal percentage, e.g. `64.3%`. Negative (expansion) keeps its sign.
  String get savedPercentageReadable =>
      '${savedPercentage.toStringAsFixed(1)}%';

  Map<String, dynamic> toJson() => {
        'jobs_completed': jobsCompleted,
        'original_bytes': totalOriginalBytes,
        'output_bytes': totalOutputBytes,
        'bytes_saved': bytesSaved,
        'bytes_saved_readable': bytesSavedReadable,
        'saved_percentage': savedPercentageReadable,
      };

  /// Builds stats from the successful jobs in [jobs].
  static BatchStats fromJobs(Iterable<ConversionJob> jobs) {
    var original = 0;
    var output = 0;
    var completed = 0;
    for (final job in jobs) {
      if (job.status != 'Done') continue;
      completed++;
      original += job.originalSizeBytes;
      output += job.outputSizeBytes;
    }
    return BatchStats(
      jobsCompleted: completed,
      totalOriginalBytes: original,
      totalOutputBytes: output,
    );
  }
}

class Converter {
  final void Function(String msg)? onLogCb;
  final void Function(ConversionJob job, double pct)? onProgress;
  bool _stopped = false;

  Converter({this.onLogCb, this.onProgress});

  void stop() {
    _stopped = true;
  }

  Future<bool> convert(ConversionJob job) async {
    job.status = 'Converting';
    try {
      // Snapshot the input size before any tool runs; the source may be
      // deleted by --delete-source on success.
      try {
        job.originalSizeBytes = File(job.filepath).lengthSync();
      } catch (_) {
        job.originalSizeBytes = 0;
      }

      bool ok = await _dispatch(job);
      if (ok && job.verify && job.targetFormat.toUpperCase() == 'CHD') {
        final chdOut = _outPath(job, job.filepath, '.chd');
        if (File(chdOut).existsSync()) {
          _log('[VERIFY] Verifying CHD integrity: ${p.basename(chdOut)}');
          final verOk = verifyChd(chdOut, onLog: _log);
          if (!verOk) ok = false;
        }
      }

      if (ok) {
        job.outputSizeBytes = _measureOutputs(job);
      }

      job.status = ok ? 'Done' : 'Failed';
      return ok;
    } catch (e) {
      job.error = e.toString();
      job.status = 'Failed';
      _log('[ERROR] $e');
      return false;
    } finally {
      _cleanup(job);
    }
  }

  /// Sums the on-disk size of every registered output. Falls back to scanning
  /// [ConversionJob.outputDir] for a file sharing the source's base name when
  /// a route registered no explicit output (e.g. plugin routes).
  int _measureOutputs(ConversionJob job) {
    var total = 0;
    for (final path in job.outputPaths) {
      try {
        final f = File(path);
        if (f.existsSync()) total += f.lengthSync();
      } catch (_) {}
    }
    if (total > 0) return total;

    try {
      final base = p.basenameWithoutExtension(job.filepath).toLowerCase();
      final dir = Directory(job.outputDir);
      if (dir.existsSync()) {
        for (final e in dir.listSync()) {
          if (e is File &&
              p.basenameWithoutExtension(e.path).toLowerCase() == base) {
            total += e.lengthSync();
          }
        }
      }
    } catch (_) {}
    return total;
  }

  Future<bool> _dispatch(ConversionJob job) async {
    final info = job.getFileInfo();
    final src = job.filepath;

    if (job.forcePlatform != null && job.forcePlatform!.trim().isNotEmpty) {
      _log(
        "[INFO] Platform override: using '${job.forcePlatform}' "
        "(auto-detected: ${info['platform'] ?? 'UNKNOWN'})",
      );
    }

    if (info.containsKey('error')) {
      _log('[ERROR] ${info['error']}');
      job.error = info['error'] as String?;
      return false;
    }

    final fmt = info['format'] as String? ?? 'UNKNOWN';
    final tgt = job.targetFormat.toUpperCase();

    // Plugin routes are resolved with core precedence: a plugin may only take
    // over a built-in route when it explicitly set "override": true in its
    // manifest. Otherwise the built-in converter wins.
    final pluginConv = PluginRegistry.instance.resolveRoute(
      fmt,
      tgt,
      builtinRoutes,
    );
    if (pluginConv != null) {
      return await _pluginConvert(job, src, pluginConv);
    }

    if (fmt == 'ECM') {
      return await _fromEcm(job, src, tgt);
    }

    // XISO / Xbox 360 / NKit / Wii U routes were decoupled in v4.0.0. They are
    // served by community `.orplug` extensions; if none is installed (the
    // plugin lookup above returned null), report a friendly, actionable error
    // rather than a missing-binary failure. This runs before the built-in
    // target check because decoupled formats advertise no core targets.
    if (requiresCommunityExtension(fmt, tgt)) {
      _log('[ERROR] $communityExtensionError');
      job.error = communityExtensionError;
      return false;
    }

    final valid = detector.getValidTargets(fmt);
    if (!valid.contains(tgt) && tgt != 'BIN/CUE' && tgt != 'FILES') {
      final err = 'Cannot convert $fmt → $tgt. '
          'Supported targets for $fmt: ${valid.isNotEmpty ? valid.join(", ") : "none"}';
      _log('[ERROR] $err');
      job.error = err;
      return false;
    }

    if (tgt == 'CHD') {
      return await _toChd(job, src, fmt, info);
    }

    if (fmt == 'CHD' && (tgt == 'ISO' || tgt == 'BIN' || tgt == 'BIN/CUE')) {
      return await _fromChd(job, src, tgt, info);
    }

    if (tgt == 'CSO') {
      return await _toCso(job, src);
    }

    if (tgt == 'RVZ') {
      return await _toRvz(job, src);
    }

    if (['RVZ', 'WIA', 'WBFS', 'GCZ'].contains(fmt) && tgt == 'ISO') {
      return await _fromNodtool(job, src, tgt);
    }

    if ((fmt == 'CSO' || fmt == 'ZSO') && tgt == 'ISO') {
      return await _csoToIso(job, src);
    }

    if (tgt == 'ECM') {
      return await _toEcm(job, src);
    }

    final err = 'Unhandled conversion route: $fmt → $tgt';
    _log('[ERROR] $err');
    job.error = err;
    return false;
  }

  Future<bool> _pluginConvert(
    ConversionJob job,
    String src,
    RegisteredConversion conv,
  ) async {
    final outName =
        detector.getOutputName(p.basename(src), conv.to.toLowerCase());
    final outPath = p.join(job.outputDir, outName);

    final idx = src.lastIndexOf('.');
    final base = idx != -1 ? src.substring(0, idx) : src;
    final cuePath = '$base.cue';

    _log(
        '[PLUGIN ${conv.pluginId}] ${p.basename(src)} → ${p.basename(outPath)}');

    final result = await PluginManager.instance.executor.run(
      conversion: conv,
      inputPath: src,
      outputPath: outPath,
      outputDir: job.outputDir,
      cuePath: File(cuePath).existsSync() ? cuePath : null,
      onLog: _log,
      onProgress: (pct) {
        job.progress = pct;
        onProgress?.call(job, pct);
      },
      parseProgress: _parseProgress,
    );

    if (result.success) {
      job.progress = 100.0;
      onProgress?.call(job, 100.0);
      _log('  ✅ Command executed successfully');
      return true;
    }

    job.error = result.error;
    _log('  ❌ ${result.error}');
    return false;
  }

  Future<bool> _toChd(
    ConversionJob job,
    String src,
    String fmt,
    Map<String, dynamic> info,
  ) async {
    final chdman = detector.getChdmanPath();
    final out = _outPath(job, src, '.chd');

    final platform = info['platform'] as String? ?? 'UNKNOWN';
    final mediaOverride = job.media?.trim().toLowerCase();

    // A CD-based disc image (CUE/BIN/GDI/CDI) has no DVD variant, so it always
    // maps to `createcd` unless the caller explicitly forces `--media dvd`.
    // Leaving the media type unassigned must never block dispatch.
    String subCmd;
    if (mediaOverride == 'dvd') {
      subCmd = 'createdvd';
    } else if (mediaOverride == 'cd') {
      subCmd = 'createcd';
    } else if (['GDI', 'CUE', 'BIN', 'CDI'].contains(fmt)) {
      subCmd = 'createcd';
    } else if (fmt == 'ISO' || fmt == 'IMG') {
      if (cdPlatforms.any(
        (kw) =>
            platform.toLowerCase() == kw.toLowerCase() ||
            platform.toLowerCase().contains(kw.toLowerCase()),
      )) {
        subCmd = 'createcd';
      } else if (dvdPlatforms.any(
        (kw) =>
            platform.toLowerCase() == kw.toLowerCase() ||
            platform.toLowerCase().contains(kw.toLowerCase()),
      )) {
        subCmd = 'createdvd';
      } else {
        final err =
            "Unsupported or ambiguous media type for platform '$platform'. Please specify --media cd or --media dvd.";
        _log('[ERROR] $err');
        job.error = err;
        return false;
      }
    } else {
      // Any other disc-image format defaults to CD.
      subCmd = 'createcd';
    }

    final compressionMap =
        subCmd == 'createcd' ? chdCdCompression : chdDvdCompression;
    final defaultCodec = subCmd == 'createcd' ? 'cdlz' : 'zlib';

    String compressionCodec;
    if (subCmd == 'createcd') {
      final codecOption = job.audioCodec?.trim().toLowerCase();
      if (codecOption == 'vorbis') {
        compressionCodec = 'cdlz,cdav';
      } else if (codecOption == 'flac') {
        compressionCodec = 'cdlz,cdfl';
      } else {
        compressionCodec = compressionMap[job.compression] ?? defaultCodec;
      }
    } else {
      compressionCodec = compressionMap[job.compression] ?? defaultCodec;
    }

    final cmd = [
      chdman,
      subCmd,
      '-i',
      src,
      '-o',
      out,
      '--compression',
      compressionCodec,
    ];

    if (fmt == 'BIN') {
      var cueInput = info['paired_cue'] as String?;
      if (cueInput == null || cueInput.isEmpty) {
        cueInput = _autoCue(src, job);
        if (cueInput != null) {
          job.tempFiles.add(cueInput);
        }
      }
      if (cueInput != null) {
        final idx = cmd.indexOf(src);
        if (idx != -1) cmd[idx] = cueInput;
      }
    }

    _log('[CHD] ${p.basename(src)} → ${p.basename(out)}');
    return await _run(cmd, job);
  }

  Future<bool> _fromChd(
    ConversionJob job,
    String src,
    String tgt,
    Map<String, dynamic> info,
  ) async {
    final chdman = detector.getChdmanPath();
    final chdType = info['chd_type'] as String? ?? 'cd';

    List<String> cmd;
    if (tgt == 'BIN' || tgt == 'BIN/CUE') {
      final cueOut = _outPath(job, src, '.cue');
      final binOut = _outPath(job, src, '.bin');
      if (chdType == 'dvd') {
        _log('[WARN] DVD-type CHD extracted as ISO (BIN/CUE is for CD images)');
        final out = _outPath(job, src, '.iso');
        cmd = [chdman, 'extractdvd', '-i', src, '-o', out];
      } else {
        cmd = [
          chdman,
          'extractcd',
          '-i',
          src,
          '-o',
          cueOut,
          '--outputbin',
          binOut,
        ];
      }
    } else {
      final out = _outPath(job, src, '.iso');
      if (chdType == 'dvd') {
        cmd = [chdman, 'extractdvd', '-i', src, '-o', out];
      } else {
        cmd = [chdman, 'extractcd', '-i', src, '-o', out];
      }
    }

    _log('[CHD EXTRACT] ${p.basename(src)} → ${p.basename(cmd.last)}');
    return await _run(cmd, job);
  }

  Future<bool> _toCso(ConversionJob job, String src) async {
    final maxcso = config.getToolPath('maxcso');
    final out = _outPath(job, src, '.cso');
    final threads = Platform.numberOfProcessors;
    final cmd = [maxcso, '--threads=$threads', src, '-o', out];
    if (job.compression == 'Max') {
      cmd.insert(1, '--use-zopfli');
    } else if (job.compression == 'High') {
      cmd.insert(1, '--use-zlib');
    }
    _log('[CSO] ${p.basename(src)} → ${p.basename(out)}');
    return await _run(cmd, job);
  }

  Future<bool> _csoToIso(ConversionJob job, String src) async {
    final maxcso = config.getToolPath('maxcso');
    final out = _outPath(job, src, '.iso');
    final cmd = [maxcso, '--decompress', src, '-o', out];
    _log('[CSO→ISO] ${p.basename(src)} → ${p.basename(out)}');
    return await _run(cmd, job);
  }

  Future<bool> _toEcm(ConversionJob job, String src) async {
    final ecm = config.getToolPath('ecm');
    final out = _outPath(job, src, 'ecm');
    final cmd = [ecm, src, out];
    _log('[ECM] ${p.basename(src)} → ${p.basename(out)}');
    return await _run(cmd, job);
  }

  Future<bool> _fromEcm(ConversionJob job, String src, String tgt) async {
    final unecm = config.getToolPath('unecm');
    final out = _outPath(job, src, tgt);
    final cmd = [unecm, src, out];
    _log('[UNECM] ${p.basename(src)} → ${p.basename(out)}');

    final ok = await _run(cmd, job);
    if (ok && File(out).existsSync()) {
      final extFound = detector.getExtension(out);
      final targetExt = tgt.toLowerCase();
      if ((targetExt == 'iso' || targetExt == 'bin') && extFound != targetExt) {
        final newOut = p.join(
          job.outputDir,
          detector.getOutputName(p.basename(out), targetExt),
        );
        try {
          File(out).renameSync(newOut);
          _log('[UNECM AUTO-DETECT] Renamed output to: ${p.basename(newOut)}');
        } catch (e) {
          _log('[WARN] Failed to rename $out to $newOut: $e');
        }
      }
    }
    return ok;
  }

  Future<bool> _toRvz(ConversionJob job, String src) async {
    final nodtool = config.getToolPath('nodtool');
    final outName = detector.getOutputName(src, 'rvz');
    final out = p.join(job.outputDir, p.basename(outName));
    job.addOutput(out);
    final cmd = [nodtool, 'convert', src, out];
    _log('[RVZ] ${p.basename(src)} → ${p.basename(out)}');
    return await _run(cmd, job);
  }

  Future<bool> _fromNodtool(ConversionJob job, String src, String tgt) async {
    final nodtool = config.getToolPath('nodtool');
    final outName = detector.getOutputName(src, 'iso');
    final out = p.join(job.outputDir, p.basename(outName));
    job.addOutput(out);
    final fmt = p.extension(src).toUpperCase().replaceAll('.', '');
    final cmd = [nodtool, 'convert', src, out];
    _log('[$fmt→ISO] ${p.basename(src)} → ${p.basename(out)}');
    return await _run(cmd, job);
  }

  Future<bool> _run(List<String> cmd, ConversionJob job) async {
    final cleanedCmd = cleanCommandArgs(cmd);
    final toolPath = cleanedCmd.first;
    final isAbsolute = p.isAbsolute(toolPath);
    if (isAbsolute && !File(toolPath).existsSync()) {
      final toolName = p.basename(toolPath);
      final err =
          'Tool not found: "$toolName" is missing from the assets folder. '
          'Please reinstall OpenROM or set the tool path manually in Settings.';
      job.error = err;
      _log('  ❌ $err');
      return false;
    }

    // Safety net: a decoupled tool must never reach Process.start. Routes are
    // already intercepted in [convert], so this only fires if a future caller
    // invokes one of the removed converters directly.
    if (decoupledToolNames.contains(p.basename(toolPath))) {
      _log('  ❌ $communityExtensionError');
      job.error = communityExtensionError;
      return false;
    }

    _log(
      '  cmd: ${cleanedCmd.asMap().entries.map((e) => e.key == 0 ? p.basename(e.value) : e.value).join(' ')}',
    );
    String lastLine = '';
    final stderrBuffer = StringBuffer();

    try {
      final process = await Process.start(
        cleanedCmd.first,
        cleanedCmd.sublist(1),
      );

      void handleLine(String line, {bool isStderr = false}) {
        if (_stopped) return;
        final trimmed = line.trimRight();
        if (trimmed.isNotEmpty) {
          lastLine = trimmed;
          _log('  $trimmed');
          if (isStderr) {
            if (stderrBuffer.isNotEmpty) stderrBuffer.writeln();
            stderrBuffer.write(trimmed);
          }
          final pct = _parseProgress(trimmed);
          if (pct != null) {
            job.progress = pct;
            if (onProgress != null) onProgress!(job, pct);
          }
        }
      }

      final stdoutDone = processStreamLines(
        process.stdout,
        (line) => handleLine(line),
      );
      final stderrDone = processStreamLines(
        process.stderr,
        (line) => handleLine(line, isStderr: true),
      );

      await Future.wait([stdoutDone, stderrDone]);
      final exitCode = await process.exitCode;

      if (_stopped) {
        job.error = 'Process terminated by user';
        return false;
      }

      if (exitCode == 0) {
        _log('  ✅ Command executed successfully');
        job.progress = 100.0;
        if (onProgress != null) onProgress!(job, 100.0);
        return true;
      } else {
        final toolName = p.basename(toolPath);
        final errDetails = stderrBuffer.isNotEmpty
            ? stderrBuffer.toString().trim()
            : (lastLine.isNotEmpty ? lastLine : 'Unknown error');
        final err = '$toolName failed with exit code $exitCode: $errDetails';
        job.error = err;
        _log('  ❌ $err');
        return false;
      }
    } catch (e) {
      final err = 'Tool failed: $e';
      job.error = err;
      _log('  ❌ $err');
      return false;
    }
  }

  String _outPath(ConversionJob job, String src, String ext) {
    final outName = detector.getOutputName(p.basename(src), ext);
    final out = p.join(job.outputDir, outName);
    job.addOutput(out);
    return out;
  }

  void _log(String msg) {
    logger.log(msg);
    if (onLogCb != null) {
      try {
        onLogCb!(msg);
      } catch (_) {}
    }
  }

  void _cleanup(ConversionJob job) {
    for (final f in job.tempFiles) {
      try {
        if (File(f).existsSync()) {
          File(f).deleteSync();
          logger.log('[CLEANUP] Removed temp file: ${p.basename(f)}');
        }
      } catch (e) {
        logger.log('[CLEANUP WARN] Could not remove $f: $e');
      }
    }
  }

  String? _autoCue(String binPath, ConversionJob job) {
    final base = p.basenameWithoutExtension(binPath);
    final binDir = p.dirname(p.canonicalize(binPath));
    final cuePath = p.join(binDir, '${base}_auto.cue');
    final binName = p.basename(binPath);
    final trackMode = detectBinMode(binPath);

    _log('[AUTO-CUE] Detected BIN mode: $trackMode');
    try {
      final f = File(cuePath);
      final buf = StringBuffer();
      buf.writeln('FILE "$binName" BINARY');
      buf.writeln('  TRACK 01 $trackMode');
      buf.writeln('    INDEX 01 00:00:00');
      f.writeAsStringSync(buf.toString());
      _log('[AUTO-CUE] Generated CUE file: ${p.basename(cuePath)}');
      return cuePath;
    } catch (e) {
      _log('[WARN] Could not write auto CUE: $e');
      return null;
    }
  }
}

double? _parseProgress(String line) {
  if (RegExp(
    r'(?:cpu|memory|ram|disk|swap|usage|load)',
    caseSensitive: false,
  ).hasMatch(line)) {
    return null;
  }

  final m = RegExp(
    r'(?:progress|complete|done)?\s*(\d+(?:\.\d+)?)\s*%',
    caseSensitive: false,
  ).firstMatch(line);
  if (m != null) {
    return double.tryParse(m.group(1)!);
  }

  final mBytes = RegExp(
    r'Wrote\s+(\d+)\s+of\s+(\d+)\s+bytes',
    caseSensitive: false,
  ).firstMatch(line);
  if (mBytes != null) {
    final written = int.parse(mBytes.group(1)!);
    final total = int.parse(mBytes.group(2)!);
    if (total > 0) {
      return (written / total * 100.0);
    }
  }

  return null;
}
