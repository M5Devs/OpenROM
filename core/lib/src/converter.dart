import 'config.dart' as config;
// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'cue_generator.dart';
import 'detector.dart' as detector;
import 'logger.dart' as logger;
import 'validator.dart';

const List<String> cdPlatformKeywords = [
  'PS1',
  'Dreamcast',
  'Saturn',
  'Sega CD',
  'PC-Engine CD',
  'Neo Geo CD'
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

class ConversionJob {
  final String filepath;
  final String outputDir;
  String targetFormat;
  final String compression;
  final bool verify;
  final String? forcePlatform;
  String status;
  double progress;
  final List<String> logLines;
  String? error;
  final List<String> tempFiles;
  Map<String, dynamic>? _fileInfo;

  ConversionJob({
    required this.filepath,
    required this.outputDir,
    required this.targetFormat,
    this.compression = 'Normal',
    this.verify = false,
    this.forcePlatform,
    this.status = 'Queued',
    this.progress = 0.0,
    List<String>? logLines,
    this.error,
    List<String>? tempFiles,
  })  : logLines = logLines ?? [],
        tempFiles = tempFiles ?? [];

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

class Converter {
  final void Function(String msg)? onLogCb;
  final void Function(ConversionJob job, double pct)? onProgress;
  bool _stopped = false;

  Converter({this.onLogCb, this.onProgress});

  void stop() {
    _stopped = true;
  }

  bool convert(ConversionJob job) {
    job.status = 'Converting';
    try {
      bool ok = _dispatch(job);
      if (ok && job.verify && job.targetFormat.toUpperCase() == 'CHD') {
        final chdOut = _outPath(job, job.filepath, '.chd');
        if (File(chdOut).existsSync()) {
          _log('[VERIFY] Verifying CHD integrity: ${p.basename(chdOut)}');
          final verOk = verifyChd(chdOut, onLog: _log);
          if (!verOk) ok = false;
        }
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

  bool _dispatch(ConversionJob job) {
    final info = job.getFileInfo();
    final src = job.filepath;

    if (job.forcePlatform != null && job.forcePlatform!.trim().isNotEmpty) {
      _log("[INFO] Platform override: using '${job.forcePlatform}' "
          "(auto-detected: ${info['platform'] ?? 'UNKNOWN'})");
    }

    if (info.containsKey('error')) {
      _log('[ERROR] ${info['error']}');
      job.error = info['error'] as String?;
      return false;
    }

    final fmt = info['format'] as String? ?? 'UNKNOWN';
    final tgt = job.targetFormat.toUpperCase();

    if (fmt == 'ECM') {
      return _fromEcm(job, src, tgt);
    }

    final valid = detector.getValidTargets(fmt);
    if (!valid.contains(tgt) && tgt != 'BIN/CUE' && tgt != 'FILES') {
      final err = 'Cannot convert $fmt → $tgt. '
          'Supported targets for $fmt: ${valid.isNotEmpty ? valid.join(', ') : 'none'}';
      _log('[ERROR] $err');
      job.error = err;
      return false;
    }

    if (tgt == 'CHD') {
      return _toChd(job, src, fmt, info);
    }

    if (fmt == 'CHD' && (tgt == 'ISO' || tgt == 'BIN' || tgt == 'BIN/CUE')) {
      return _fromChd(job, src, tgt, info);
    }

    if (tgt == 'CSO') {
      return _toCso(job, src);
    }

    if (tgt == 'RVZ') {
      return _toRvz(job, src);
    }

    if (['RVZ', 'WIA', 'WBFS', 'GCZ'].contains(fmt) && tgt == 'ISO') {
      return _fromNodtool(job, src, tgt);
    }

    if ((fmt == 'CSO' || fmt == 'ZSO') && tgt == 'ISO') {
      return _csoToIso(job, src);
    }

    if (tgt == 'ECM') {
      return _toEcm(job, src);
    }

    if (fmt == 'XISO' && (tgt == 'ISO' || tgt == 'FILES')) {
      return _xisoToFiles(job, src);
    }

    if (tgt == 'XISO') {
      return _toXiso(job, src);
    }

    if ((['WUD', 'WUX', 'NKIT'].contains(fmt) && tgt == 'ISO') ||
        (fmt == 'ISO' && tgt == 'NKIT')) {
      return _nkitConvert(job, src, tgt);
    }

    if ((fmt == 'CCI' || fmt == 'ZAR') && tgt == 'ISO') {
      return _xboxConvert(job, src, fmt);
    }

    final err = 'Unhandled conversion route: $fmt → $tgt';
    _log('[ERROR] $err');
    job.error = err;
    return false;
  }

  bool _toChd(
      ConversionJob job, String src, String fmt, Map<String, dynamic> info) {
    final chdman = detector.getChdmanPath();
    final out = _outPath(job, src, '.chd');

    String subCmd;
    if (['GDI', 'CUE', 'BIN', 'CDI'].contains(fmt)) {
      subCmd = 'createcd';
    } else if (fmt == 'ISO' || fmt == 'IMG') {
      final platform = info['platform'] as String? ?? '';
      subCmd = cdPlatformKeywords.any((kw) => platform.contains(kw))
          ? 'createcd'
          : 'createdvd';
    } else {
      subCmd = 'createcd';
    }

    final compressionMap =
        subCmd == 'createcd' ? chdCdCompression : chdDvdCompression;
    final defaultCodec = subCmd == 'createcd' ? 'cdlz' : 'zlib';
    final cmd = [
      chdman,
      subCmd,
      '-i',
      src,
      '-o',
      out,
      '--compression',
      compressionMap[job.compression] ?? defaultCodec
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
    return _run(cmd, job);
  }

  bool _fromChd(
      ConversionJob job, String src, String tgt, Map<String, dynamic> info) {
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
        cmd = [chdman, 'extractcd', '-i', src, '-o', cueOut, '--outputbin', binOut];
      }
    } else {
      final out = _outPath(job, src, '.iso');
      if (chdType == 'dvd') {
        cmd = [chdman, 'extractdvd', '-i', src, '-o', out];
      } else {
        cmd = [chdman, 'extractcd', '-i', src, '-o', out];
      }
    }

    _log('[CHD EXTRACT] ${p.basename(src)} → $tgt');
    return _run(cmd, job);
  }

  bool _toCso(ConversionJob job, String src) {
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
    return _run(cmd, job);
  }

  bool _csoToIso(ConversionJob job, String src) {
    final maxcso = config.getToolPath('maxcso');
    final out = _outPath(job, src, '.iso');
    final cmd = [maxcso, '--decompress', src, '-o', out];
    _log('[CSO→ISO] ${p.basename(src)} → ${p.basename(out)}');
    return _run(cmd, job);
  }

  bool _toEcm(ConversionJob job, String src) {
    final ecm = config.getToolPath('ecm');
    final out = _outPath(job, src, 'ecm');
    final cmd = [ecm, src, out];
    _log('[ECM] ${p.basename(src)} → ${p.basename(out)}');
    return _run(cmd, job);
  }

  bool _fromEcm(ConversionJob job, String src, String tgt) {
    final unecm = config.getToolPath('unecm');
    final out = _outPath(job, src, tgt);
    final cmd = [unecm, src, out];
    _log('[UNECM] ${p.basename(src)} → ${p.basename(out)}');

    final ok = _run(cmd, job);
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

  bool _toXiso(ConversionJob job, String src) {
    final xiso = config.getToolPath('extract-xiso');
    final cmd = [xiso, '-r', src];
    _log('[XISO] ${p.basename(src)} — repacking to XISO...');
    return _run(cmd, job);
  }

  bool _xisoToFiles(ConversionJob job, String src) {
    final xiso = config.getToolPath('extract-xiso');
    final base = p.basenameWithoutExtension(src);
    final outDir = p.join(job.outputDir, '${base}_extracted');
    Directory(outDir).createSync(recursive: true);
    final cmd = [xiso, '-x', src, '-d', outDir];
    _log('[XISO→FILES] Extracting ${p.basename(src)} → $outDir/');
    _log('[XISO→FILES] Output is a folder of extracted files, not a single ISO.');
    return _run(cmd, job);
  }

  bool _toRvz(ConversionJob job, String src) {
    final nodtool = config.getToolPath('nodtool');
    final outName = detector.getOutputName(src, 'rvz');
    final out = p.join(job.outputDir, p.basename(outName));
    final cmd = [nodtool, 'convert', src, out];
    _log('[RVZ] ${p.basename(src)} → ${p.basename(out)}');
    return _run(cmd, job);
  }

  bool _fromNodtool(ConversionJob job, String src, String tgt) {
    final nodtool = config.getToolPath('nodtool');
    final outName = detector.getOutputName(src, 'iso');
    final out = p.join(job.outputDir, p.basename(outName));
    final fmt = p.extension(src).toUpperCase().replaceAll('.', '');
    final cmd = [nodtool, 'convert', src, out];
    _log('[$fmt→ISO] ${p.basename(src)} → ${p.basename(out)}');
    return _run(cmd, job);
  }

  bool _nkitConvert(ConversionJob job, String src, String tgt) {
    final nkit = config.getToolPath('nkit');
    final ext = tgt == 'NKIT' ? 'nkit.iso' : tgt.toLowerCase();
    final out = _outPath(job, src, ext);
    final cmd = [nkit, 'convert', '-i', src, '-o', out];
    _log('[NKIT] ${p.basename(src)} → ${p.basename(out)}');
    return _run(cmd, job);
  }

  bool _xboxConvert(ConversionJob job, String src, String fmt) {
    if (Platform.isMacOS) {
      job.error =
          'Xbox format conversion is not supported on macOS. '
          'XGDTool does not currently provide a macOS build.';
      _log('  ❌ ${job.error}');
      return false;
    }
    final xgdtool = config.getToolPath('xgdtool');
    final cmd = [xgdtool, '--xiso', src, '--out', job.outputDir];
    _log('[Xbox→ISO] ${p.basename(src)} → ISO via XGDTool');
    return _run(cmd, job);
  }

  bool _run(List<String> cmd, ConversionJob job) {
    final toolPath = cmd.first;
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

    _log('  cmd: ${cmd.asMap().entries.map((e) => e.key == 0 ? p.basename(e.value) : e.value).join(' ')}');
    String lastLine = '';

    try {
      final process = Process.runSync(
        cmd.first,
        cmd.sublist(1),
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );

      final combined = '${process.stdout}\n${process.stderr}';
      final lines = const LineSplitter().convert(combined);

      for (final line in lines) {
        if (_stopped) {
          job.error = 'Process terminated by user';
          return false;
        }
        final trimmed = line.trimRight();
        if (trimmed.isNotEmpty) {
          lastLine = trimmed;
          _log('  $trimmed');
          final pct = _parseProgress(trimmed);
          if (pct != null) {
            job.progress = pct;
            if (onProgress != null) onProgress!(job, pct);
          }
        }
      }

      if (process.exitCode == 0) {
        _log('  ✅ Command executed successfully');
        job.progress = 100.0;
        if (onProgress != null) onProgress!(job, 100.0);
        return true;
      } else {
        final err = lastLine.isNotEmpty
            ? 'Process failed (code ${process.exitCode}): $lastLine'
            : 'Process failed with exit code ${process.exitCode}';
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
    return p.join(job.outputDir, outName);
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
  if (RegExp(r'\b(?:cpu|memory|ram|disk|swap|usage|load)\b', caseSensitive: false)
      .hasMatch(line)) {
    return null;
  }

  final m = RegExp(r'(?:progress|complete|done)?\s*(\d+(?:\.\d+)?)\s*%',
          caseSensitive: false)
      .firstMatch(line);
  if (m != null) {
    return double.tryParse(m.group(1)!);
  }

  final mBytes = RegExp(r'Wrote\s+(\d+)\s+of\s+(\d+)\s+bytes', caseSensitive: false)
      .firstMatch(line);
  if (mBytes != null) {
    final written = int.parse(mBytes.group(1)!);
    final total = int.parse(mBytes.group(2)!);
    if (total > 0) {
      return (written / total * 100.0);
    }
  }

  return null;
}
