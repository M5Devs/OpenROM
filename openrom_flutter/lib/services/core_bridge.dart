// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3 + Commons Clause

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../core/errors.dart';
import '../models/conversion_job.dart';
import '../models/rom_file.dart';

typedef ProgressCallback = void Function(double percent);
typedef LogCallback = void Function(String log);
typedef DoneCallback = void Function(bool success, String? error);

class OpenROMException implements Exception {
  final OpenROMError error;
  final String? details;

  OpenROMException(this.error, {this.details});

  @override
  String toString() => 'OpenROMException($error, details: $details)';
}

class CoreBridge {
  static String? _cachedCorePath;

  static Future<String> getCoreExecutablePath() async {
    if (_cachedCorePath != null && File(_cachedCorePath!).existsSync()) {
      return _cachedCorePath!;
    }

    final String exeDir = File(Platform.resolvedExecutable).parent.path;
    final String binaryName = Platform.isWindows ? 'openrom-core.exe' : 'openrom-core';
    final String sameDirBinary = '$exeDir${Platform.pathSeparator}$binaryName';

    if (File(sameDirBinary).existsSync()) {
      _cachedCorePath = sameDirBinary;
      return _cachedCorePath!;
    }

    if (File(binaryName).existsSync()) {
      _cachedCorePath = binaryName;
      return _cachedCorePath!;
    }

    if (File('main.py').existsSync()) {
      _cachedCorePath = Platform.isWindows ? 'python' : 'python3';
      return _cachedCorePath!;
    }

    _cachedCorePath = binaryName;
    return _cachedCorePath!;
  }

  static Future<bool> coreExists() async {
    final corePath = await getCoreExecutablePath();
    if (corePath.endsWith('python3') || corePath.endsWith('python')) {
      return File('main.py').existsSync();
    }
    return File(corePath).existsSync();
  }

  static Future<RomFile?> detectFile(String filepath) async {
    if (!await coreExists()) {
      throw OpenROMException(OpenROMError.coreNotFound);
    }
    if (!File(filepath).existsSync()) {
      throw OpenROMException(OpenROMError.fileNotFound, details: 'Input file not found: $filepath');
    }

    try {
      final corePath = await getCoreExecutablePath();
      final List<String> args = [];

      if (corePath.endsWith('python3') || corePath.endsWith('python')) {
        args.addAll(['main.py', '--json', '--detect', filepath]);
      } else {
        args.addAll(['--json', '--detect', filepath]);
      }

      final result = await Process.run(corePath, args);
      if (result.exitCode == 0) {
        final lines = LineSplitter.split(result.stdout.toString()).where((l) => l.trim().isNotEmpty).toList();
        if (lines.isNotEmpty) {
          final Map<String, dynamic> jsonMap = jsonDecode(lines.last);
          return RomFile.fromJson(jsonMap);
        }
      } else if (result.exitCode == 2) {
        throw OpenROMException(OpenROMError.unsupportedFormat, details: result.stderr.toString());
      } else {
        throw OpenROMException(OpenROMError.conversionFailed, details: result.stderr.toString());
      }
    } on FileSystemException catch (e) {
      final err = (e.osError?.errorCode == 13 || e.message.toLowerCase().contains('permission'))
          ? OpenROMError.permissionDenied
          : OpenROMError.fileNotFound;
      throw OpenROMException(err, details: e.toString());
    } on ProcessException catch (e) {
      throw OpenROMException(OpenROMError.toolFailed, details: e.toString());
    } catch (e) {
      if (e is OpenROMException) rethrow;
      debugPrint('Error running detectFile: $e');
    }
    return null;
  }

  static Future<void> runConversion({
    required ConversionJob job,
    required String outputDir,
    required ProgressCallback onProgress,
    required LogCallback onLog,
    required DoneCallback onDone,
  }) async {
    if (!await coreExists()) {
      onDone(false, 'openrom-core binary missing');
      throw OpenROMException(OpenROMError.coreNotFound);
    }

    if (!File(job.romFile.filepath).existsSync()) {
      onDone(false, 'Input file not found: ${job.romFile.filepath}');
      throw OpenROMException(OpenROMError.fileNotFound, details: 'File not found: ${job.romFile.filepath}');
    }

    if (outputDir.isNotEmpty && !Directory(outputDir).existsSync()) {
      onDone(false, 'Output directory does not exist: $outputDir');
      throw OpenROMException(OpenROMError.outputDirNotFound, details: 'Output directory not found: $outputDir');
    }

    try {
      final corePath = await getCoreExecutablePath();
      final List<String> args = [];

      if (corePath.endsWith('python3') || corePath.endsWith('python')) {
        args.add('main.py');
      }

      args.addAll([
        '--json',
        '--convert', job.romFile.filepath,
        '--format', job.targetFormat,
        '--compression', job.compression,
      ]);

      if (job.verify) {
        args.add('--verify');
      }

      if (outputDir.isNotEmpty) {
        args.addAll(['--output', outputDir]);
      }

      final process = await Process.start(corePath, args);
      final stderrLog = StringBuffer();

      process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
        if (line.trim().isEmpty) return;
        try {
          final Map<String, dynamic> event = jsonDecode(line);
          final type = event['type'];
          if (type == 'progress') {
            final double pct = (event['percent'] as num).toDouble();
            onProgress(pct);
          } else if (type == 'log') {
            final String msg = event['message'] ?? '';
            onLog(msg);
          } else if (type == 'done') {
            final bool success = event['success'] ?? false;
            final String? err = event['error'];
            onDone(success, err);
          } else if (type == 'error') {
            final String msg = event['message'] ?? 'Unknown error';
            onLog('[ERROR] $msg');
            stderrLog.writeln(msg);
          }
        } catch (_) {
          onLog(line);
        }
      });

      process.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
        if (line.trim().isNotEmpty) {
          onLog('[STDERR] $line');
          stderrLog.writeln(line);
        }
      });

      final exitCode = await process.exitCode;
      if (exitCode != 0) {
        final details = stderrLog.isNotEmpty
            ? stderrLog.toString().trim()
            : 'Process exited with code $exitCode';
        onDone(false, details);
        if (exitCode == 1) {
          throw OpenROMException(OpenROMError.conversionFailed, details: details);
        } else if (exitCode == 2) {
          throw OpenROMException(OpenROMError.unsupportedFormat, details: details);
        } else {
          throw OpenROMException(OpenROMError.unknownError, details: details);
        }
      }
    } on FileSystemException catch (e) {
      final err = (e.osError?.errorCode == 13 || e.message.toLowerCase().contains('permission'))
          ? OpenROMError.permissionDenied
          : OpenROMError.fileNotFound;
      onDone(false, e.toString());
      throw OpenROMException(err, details: e.toString());
    } on ProcessException catch (e) {
      onDone(false, e.toString());
      throw OpenROMException(OpenROMError.toolFailed, details: e.toString());
    } catch (e) {
      if (e is OpenROMException) rethrow;
      onDone(false, e.toString());
      throw OpenROMException(OpenROMError.unknownError, details: e.toString());
    }
  }

  static Future<void> runCompress({
    required List<String> files,
    required String format,
    required String level,
    required bool deleteSource,
    String? outputDir,
    ProgressCallback? onProgress,
    LogCallback? onLog,
    DoneCallback? onDone,
  }) async {
    if (!await coreExists()) {
      onDone?.call(false, 'openrom-core binary missing');
      throw OpenROMException(OpenROMError.coreNotFound);
    }

    try {
      final corePath = await getCoreExecutablePath();
      final List<String> args = [];

      if (corePath.endsWith('python3') || corePath.endsWith('python')) {
        args.add('main.py');
      }

      args.addAll([
        '--json',
        '--compress', ...files,
        '--format', format,
        '--level', level,
      ]);

      if (deleteSource) {
        args.add('--delete-source');
      }

      if (outputDir != null && outputDir.isNotEmpty) {
        args.addAll(['--output', outputDir]);
      }

      final process = await Process.start(corePath, args);
      final stderrLog = StringBuffer();

      process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
        if (line.trim().isEmpty) return;
        try {
          final Map<String, dynamic> event = jsonDecode(line);
          final type = event['type'];
          if (type == 'progress') {
            final double pct = (event['percent'] as num).toDouble();
            onProgress?.call(pct);
          } else if (type == 'log') {
            final String msg = event['message'] ?? '';
            onLog?.call(msg);
          } else if (type == 'done') {
            final bool success = event['success'] ?? false;
            final String? err = event['error'];
            onDone?.call(success, err);
          } else if (type == 'error') {
            final String msg = event['message'] ?? 'Unknown error';
            onLog?.call('[ERROR] $msg');
            stderrLog.writeln(msg);
          }
        } catch (_) {
          onLog?.call(line);
        }
      });

      process.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
        if (line.trim().isNotEmpty) {
          onLog?.call('[STDERR] $line');
          stderrLog.writeln(line);
        }
      });

      final exitCode = await process.exitCode;
      if (exitCode != 0) {
        final details = stderrLog.isNotEmpty
            ? stderrLog.toString().trim()
            : 'Process exited with code $exitCode';
        onDone?.call(false, details);
        throw OpenROMException(OpenROMError.conversionFailed, details: details);
      }
    } on FileSystemException catch (e) {
      final err = (e.osError?.errorCode == 13 || e.message.toLowerCase().contains('permission'))
          ? OpenROMError.permissionDenied
          : OpenROMError.fileNotFound;
      onDone?.call(false, e.toString());
      throw OpenROMException(err, details: e.toString());
    } on ProcessException catch (e) {
      onDone?.call(false, e.toString());
      throw OpenROMException(OpenROMError.toolFailed, details: e.toString());
    } catch (e) {
      if (e is OpenROMException) rethrow;
      onDone?.call(false, e.toString());
      throw OpenROMException(OpenROMError.unknownError, details: e.toString());
    }
  }

  static Future<void> runExtract({
    required List<String> files,
    required bool deleteSource,
    String? outputDir,
    ProgressCallback? onProgress,
    LogCallback? onLog,
    DoneCallback? onDone,
  }) async {
    if (!await coreExists()) {
      onDone?.call(false, 'openrom-core binary missing');
      throw OpenROMException(OpenROMError.coreNotFound);
    }

    try {
      final corePath = await getCoreExecutablePath();
      final List<String> args = [];

      if (corePath.endsWith('python3') || corePath.endsWith('python')) {
        args.add('main.py');
      }

      args.addAll([
        '--json',
        '--extract', ...files,
      ]);

      if (deleteSource) {
        args.add('--delete-source');
      }

      if (outputDir != null && outputDir.isNotEmpty) {
        args.addAll(['--output', outputDir]);
      }

      final process = await Process.start(corePath, args);
      final stderrLog = StringBuffer();

      process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
        if (line.trim().isEmpty) return;
        try {
          final Map<String, dynamic> event = jsonDecode(line);
          final type = event['type'];
          if (type == 'progress') {
            final double pct = (event['percent'] as num).toDouble();
            onProgress?.call(pct);
          } else if (type == 'log') {
            final String msg = event['message'] ?? '';
            onLog?.call(msg);
          } else if (type == 'done') {
            final bool success = event['success'] ?? false;
            final String? err = event['error'];
            onDone?.call(success, err);
          } else if (type == 'error') {
            final String msg = event['message'] ?? 'Unknown error';
            onLog?.call('[ERROR] $msg');
            stderrLog.writeln(msg);
          }
        } catch (_) {
          onLog?.call(line);
        }
      });

      process.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
        if (line.trim().isNotEmpty) {
          onLog?.call('[STDERR] $line');
          stderrLog.writeln(line);
        }
      });

      final exitCode = await process.exitCode;
      if (exitCode != 0) {
        final details = stderrLog.isNotEmpty
            ? stderrLog.toString().trim()
            : 'Process exited with code $exitCode';
        onDone?.call(false, details);
        throw OpenROMException(OpenROMError.conversionFailed, details: details);
      }
    } on FileSystemException catch (e) {
      final err = (e.osError?.errorCode == 13 || e.message.toLowerCase().contains('permission'))
          ? OpenROMError.permissionDenied
          : OpenROMError.fileNotFound;
      onDone?.call(false, e.toString());
      throw OpenROMException(err, details: e.toString());
    } on ProcessException catch (e) {
      onDone?.call(false, e.toString());
      throw OpenROMException(OpenROMError.toolFailed, details: e.toString());
    } catch (e) {
      if (e is OpenROMException) rethrow;
      onDone?.call(false, e.toString());
      throw OpenROMException(OpenROMError.unknownError, details: e.toString());
    }
  }

  static Future<String> generateM3u({
    required List<String> discFiles,
    required String outputDir,
    bool relative = true,
  }) async {
    if (!await coreExists()) {
      throw OpenROMException(OpenROMError.coreNotFound);
    }

    try {
      final corePath = await getCoreExecutablePath();
      final List<String> args = [];

      if (corePath.endsWith('python3') || corePath.endsWith('python')) {
        args.add('main.py');
      }

      args.addAll([
        '--json',
        '--m3u', ...discFiles,
        '--output', outputDir,
      ]);

      if (!relative) {
        args.add('--absolute');
      }

      final result = await Process.run(corePath, args);
      if (result.exitCode == 0) {
        final lines = LineSplitter.split(result.stdout.toString()).where((l) => l.trim().isNotEmpty).toList();
        for (final line in lines.reversed) {
          try {
            final Map<String, dynamic> event = jsonDecode(line);
            if (event['type'] == 'done' && event['success'] == true) {
              return event['output'] as String;
            }
          } catch (_) {}
        }
      }
      final err = result.stderr.toString().trim();
      throw OpenROMException(OpenROMError.conversionFailed, details: err.isNotEmpty ? err : 'M3U generation failed');
    } on FileSystemException catch (e) {
      final err = (e.osError?.errorCode == 13 || e.message.toLowerCase().contains('permission'))
          ? OpenROMError.permissionDenied
          : OpenROMError.fileNotFound;
      throw OpenROMException(err, details: e.toString());
    } on ProcessException catch (e) {
      throw OpenROMException(OpenROMError.toolFailed, details: e.toString());
    } catch (e) {
      if (e is OpenROMException) rethrow;
      throw OpenROMException(OpenROMError.unknownError, details: e.toString());
    }
  }

  static Future<String> getVersion() async {
    try {
      if (!await coreExists()) {
        return 'OpenROM v2.2.0';
      }
      final corePath = await getCoreExecutablePath();
      final List<String> args = [];
      if (corePath.endsWith('python3') || corePath.endsWith('python')) {
        args.addAll(['main.py', '--version']);
      } else {
        args.add('--version');
      }
      final result = await Process.run(corePath, args);
      final out = result.stdout.toString().trim();
      return out.isNotEmpty ? out : 'OpenROM v2.2.0';
    } catch (_) {
      return 'OpenROM v2.2.0';
    }
  }
}
