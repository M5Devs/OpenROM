// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3 + Commons Clause

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../core/errors.dart';
import 'core_bridge.dart';

class HeaderInfo {
  final String system;
  final int headerSize;
  final bool hasHeader;
  final String confidence;

  HeaderInfo({
    required this.system,
    required this.headerSize,
    required this.hasHeader,
    required this.confidence,
  });

  factory HeaderInfo.fromJson(Map<String, dynamic> json) {
    return HeaderInfo(
      system: json['system'] ?? '',
      headerSize: (json['header_size'] as num?)?.toInt() ?? 0,
      hasHeader: json['has_header'] ?? false,
      confidence: json['confidence'] ?? 'unlikely',
    );
  }
}

class CueResult {
  final String cuePath;
  final String detectedMode;

  CueResult({
    required this.cuePath,
    required this.detectedMode,
  });
}

class BinMergeResult {
  final String mergedBinPath;
  final String mergedCuePath;
  final int tracksCount;

  BinMergeResult({
    required this.mergedBinPath,
    required this.mergedCuePath,
    required this.tracksCount,
  });
}

class ToolsService {
  Future<CueResult> generateCue({
    required String binPath,
    String? outputDir,
  }) async {
    if (!await CoreBridge.coreExists()) {
      throw OpenROMException(OpenROMError.coreNotFound);
    }
    if (!File(binPath).existsSync()) {
      throw OpenROMException(OpenROMError.fileNotFound, details: 'BIN file not found: $binPath');
    }

    try {
      final corePath = await CoreBridge.getCoreExecutablePath();
      final List<String> args = [];

      if (corePath.endsWith('python3') || corePath.endsWith('python')) {
        args.add('main.py');
      }

      args.addAll([
        '--json',
        '--generate-cue', binPath,
      ]);

      if (outputDir != null && outputDir.isNotEmpty) {
        args.addAll(['--output', outputDir]);
      }

      final result = await Process.run(corePath, args);
      if (result.exitCode == 0) {
        final lines = LineSplitter.split(result.stdout.toString()).where((l) => l.trim().isNotEmpty).toList();
        for (final line in lines.reversed) {
          try {
            final Map<String, dynamic> event = jsonDecode(line);
            if (event['type'] == 'done' && event['success'] == true) {
              return CueResult(
                cuePath: event['output'] as String,
                detectedMode: event['detected_mode'] as String? ?? 'MODE2/2352',
              );
            }
          } catch (_) {}
        }
      }
      final err = result.stderr.toString().trim();
      throw OpenROMException(OpenROMError.conversionFailed, details: err.isNotEmpty ? err : 'CUE generation failed');
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

  Future<BinMergeResult> mergeBins({
    required String cuePath,
    String? outputDir,
    ProgressCallback? onProgress,
  }) async {
    if (!await CoreBridge.coreExists()) {
      throw OpenROMException(OpenROMError.coreNotFound);
    }
    if (!File(cuePath).existsSync()) {
      throw OpenROMException(OpenROMError.fileNotFound, details: 'CUE file not found: $cuePath');
    }

    try {
      final corePath = await CoreBridge.getCoreExecutablePath();
      final List<String> args = [];

      if (corePath.endsWith('python3') || corePath.endsWith('python')) {
        args.add('main.py');
      }

      args.addAll([
        '--json',
        '--merge-bins', cuePath,
      ]);

      if (outputDir != null && outputDir.isNotEmpty) {
        args.addAll(['--output', outputDir]);
      }

      final process = await Process.start(corePath, args);
      final stderrLog = StringBuffer();
      BinMergeResult? mergeResult;

      process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
        if (line.trim().isEmpty) return;
        try {
          final Map<String, dynamic> event = jsonDecode(line);
          final type = event['type'];
          if (type == 'progress') {
            final double pct = (event['percent'] as num).toDouble();
            onProgress?.call(pct);
          } else if (type == 'done' && event['success'] == true) {
            mergeResult = BinMergeResult(
              mergedBinPath: event['merged_bin'] as String,
              mergedCuePath: event['merged_cue'] as String,
              tracksCount: (event['tracks_count'] as num?)?.toInt() ?? 0,
            );
          } else if (type == 'error') {
            stderrLog.writeln(event['message'] ?? '');
          }
        } catch (_) {}
      });

      process.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
        if (line.trim().isNotEmpty) {
          stderrLog.writeln(line);
        }
      });

      final exitCode = await process.exitCode;
      if (exitCode == 0 && mergeResult != null) {
        return mergeResult!;
      }

      final details = stderrLog.isNotEmpty
          ? stderrLog.toString().trim()
          : 'Process exited with code $exitCode';
      throw OpenROMException(OpenROMError.conversionFailed, details: details);
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

  Future<HeaderInfo?> detectHeader(String romPath) async {
    if (!await CoreBridge.coreExists()) {
      throw OpenROMException(OpenROMError.coreNotFound);
    }
    if (!File(romPath).existsSync()) {
      throw OpenROMException(OpenROMError.fileNotFound, details: 'ROM file not found: $romPath');
    }

    try {
      final corePath = await CoreBridge.getCoreExecutablePath();
      final List<String> args = [];

      if (corePath.endsWith('python3') || corePath.endsWith('python')) {
        args.add('main.py');
      }

      args.addAll([
        '--json',
        '--detect-header', romPath,
      ]);

      final result = await Process.run(corePath, args);
      if (result.exitCode == 0) {
        final lines = LineSplitter.split(result.stdout.toString()).where((l) => l.trim().isNotEmpty).toList();
        for (final line in lines.reversed) {
          try {
            final Map<String, dynamic> event = jsonDecode(line);
            if (event['type'] == 'done' && event['success'] == true) {
              return HeaderInfo.fromJson(event);
            }
          } catch (_) {}
        }
      }
      return null;
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

  Future<String> removeHeader({
    required String romPath,
    String? outputDir,
    bool backup = true,
  }) async {
    if (!await CoreBridge.coreExists()) {
      throw OpenROMException(OpenROMError.coreNotFound);
    }
    if (!File(romPath).existsSync()) {
      throw OpenROMException(OpenROMError.fileNotFound, details: 'ROM file not found: $romPath');
    }

    try {
      final corePath = await CoreBridge.getCoreExecutablePath();
      final List<String> args = [];

      if (corePath.endsWith('python3') || corePath.endsWith('python')) {
        args.add('main.py');
      }

      args.addAll([
        '--json',
        '--remove-header', romPath,
      ]);

      if (!backup) {
        args.add('--no-backup');
      }

      if (outputDir != null && outputDir.isNotEmpty) {
        args.addAll(['--output', outputDir]);
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
      throw OpenROMException(OpenROMError.conversionFailed, details: err.isNotEmpty ? err : 'Header removal failed');
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
}
