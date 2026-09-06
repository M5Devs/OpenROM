// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3 + Commons Clause

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/conversion_job.dart';
import '../models/rom_file.dart';

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

    // Fallback: search relative to current working directory or system PATH
    if (File(binaryName).existsSync()) {
      _cachedCorePath = binaryName;
      return _cachedCorePath!;
    }

    // Fallback to python script execution during dev / debug
    if (File('main.py').existsSync()) {
      _cachedCorePath = 'python3';
      return _cachedCorePath!;
    }

    _cachedCorePath = binaryName;
    return _cachedCorePath!;
  }

  static Future<RomFile?> detectFile(String filepath) async {
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
      }
    } catch (e) {
      debugPrint('Error running detectFile: $e');
    }
    return null;
  }

  static Future<void> runConversion({
    required ConversionJob job,
    required String outputDir,
    required Function(double percent) onProgress,
    required Function(String log) onLog,
    required Function(bool success, String? error) onDone,
  }) async {
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
          }
        } catch (_) {
          // Plain text log line fallback
          onLog(line);
        }
      });

      process.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
        if (line.trim().isNotEmpty) {
          onLog('[STDERR] $line');
        }
      });

      final exitCode = await process.exitCode;
      if (exitCode != 0) {
        onDone(false, 'Process exited with code $exitCode');
      }
    } catch (e) {
      onDone(false, e.toString());
    }
  }

  static Future<String> getVersion() async {
    try {
      final corePath = await getCoreExecutablePath();
      final List<String> args = [];
      if (corePath.endsWith('python3') || corePath.endsWith('python')) {
        args.addAll(['main.py', '--version']);
      } else {
        args.add('--version');
      }
      final result = await Process.run(corePath, args);
      return result.stdout.toString().trim();
    } catch (_) {
      return 'OpenROM v2.2.0';
    }
  }
}
