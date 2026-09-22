// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

const Set<String> excludedExtensions = {
  '.chd',
  '.cso',
  '.rvz',
  '.7z',
  '.zip',
  '.gz',
  '.zst',
  '.csz',
  '.zso'
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
  bool _stopped = false;

  Compressor({this.onLog, this.onProgress});

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

    if (!File(job.filepath).existsSync() && !Directory(job.filepath).existsSync()) {
      job.status = 'Failed';
      job.error = 'File or directory not found: ${job.filepath}';
      _log('[ERROR] ${job.error}');
      return false;
    }

    if (isAlreadyCompressed(job.filepath)) {
      job.status = 'Done';
      job.progress = 100.0;
      job.error = 'Skipped (already compressed)';
      _log('[SKIP] ${p.basename(job.filepath)} is already compressed. Skipped.');
      _updateProgress(job, 100.0);
      return true;
    }

    job.status = 'Compressing';
    _updateProgress(job, 0.0);
    Directory(job.outputDir).createSync(recursive: true);

    try {
      final success = _compressZip(job);
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

    job.status = 'Extracting';
    _updateProgress(job, 0.0);
    Directory(job.outputDir).createSync(recursive: true);

    try {
      final success = _extractZip(job);
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

  bool _compressZip(CompressionJob job) {
    final baseName = p.basenameWithoutExtension(job.filepath);
    final outPath = p.join(job.outputDir, '$baseName.zip');
    _log('[ZIP] Compressing ${p.basename(job.filepath)} → ${p.basename(outPath)}');

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

    final bytes = File(job.filepath).readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);

    final total = archive.length == 0 ? 1 : archive.length;
    final basePath = p.normalize(p.canonicalize(job.outputDir));

    for (int i = 0; i < archive.length; i++) {
      if (_stopped) return false;
      final file = archive[i];
      final destPath = p.normalize(p.join(basePath, file.name));

      // Zip-Slip security check
      if (!destPath.startsWith(basePath + p.separator) && destPath != basePath) {
        throw FormatException('Malicious archive entry (Zip Slip): ${file.name}');
      }

      if (file.isFile) {
        final data = file.content as List<int>;
        File(destPath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(data);
      } else {
        Directory(destPath).createSync(recursive: true);
      }

      final pct = ((i + 1) / total) * 100.0;
      _updateProgress(job, pct);
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
