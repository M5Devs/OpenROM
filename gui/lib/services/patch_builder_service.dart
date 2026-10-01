// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/errors.dart';
import '../patcher/bps_builder.dart';
import '../patcher/ebp_builder.dart';
import '../patcher/ips32_builder.dart';
import '../patcher/ips_builder.dart';
import '../patcher/patcher.dart';
import '../patcher/ups_builder.dart';
import '../patcher/xdelta_builder.dart';
import 'core_bridge.dart';

class PatchBuildReport {
  final String format;
  final int outputSizeBytes;
  final String outputPath;

  const PatchBuildReport({
    required this.format,
    required this.outputSizeBytes,
    required this.outputPath,
  });
}

/// Top-level function executed inside [compute] isolate.
Future<PatchBuildReport> _buildPatchIsolate(Map<String, String> params) async {
  final originalPath = params['originalPath']!;
  final modifiedPath = params['modifiedPath']!;
  final outputPath = params['outputPath']!;
  final format = params['format']!.toLowerCase();

  final origFile = File(originalPath);
  final modFile = File(modifiedPath);
  final outFile = File(outputPath);

  if (!origFile.existsSync()) {
    throw PatchException('Original ROM file not found: $originalPath');
  }
  if (!modFile.existsSync()) {
    throw PatchException('Modified ROM file not found: $modifiedPath');
  }

  switch (format) {
    case 'xdelta':
      final builder = XdeltaBuilder(
        originalFile: origFile,
        modifiedFile: modFile,
        outputFile: outFile,
      );
      await builder.build();
      break;

    case 'ips':
      final builder = IpsBuilder(
        originalFile: origFile,
        modifiedFile: modFile,
        outputFile: outFile,
      );
      await builder.build();
      break;

    case 'ips32':
      final builder = IPS32Builder(
        originalFile: origFile,
        modifiedFile: modFile,
        outputFile: outFile,
      );
      await builder.build();
      break;

    case 'bps':
      final builder = BpsBuilder(
        originalFile: origFile,
        modifiedFile: modFile,
        outputFile: outFile,
      );
      await builder.build();
      break;

    case 'ebp':
      final builder = EbpBuilder(
        originalFile: origFile,
        modifiedFile: modFile,
        outputFile: outFile,
      );
      await builder.build();
      break;

    case 'ups':
      final builder = UpsBuilder(
        originalFile: origFile,
        modifiedFile: modFile,
        outputFile: outFile,
      );
      await builder.build();
      break;

    default:
      throw PatchException('Unsupported output format: $format');
  }

  if (!outFile.existsSync()) {
    throw PatchException('Patch file was not generated.');
  }

  final size = await outFile.length();

  return PatchBuildReport(
    format: format.toUpperCase(),
    outputSizeBytes: size,
    outputPath: outputPath,
  );
}

class PatchBuilderService {
  Future<PatchBuildReport> buildPatch({
    required String originalPath,
    required String modifiedPath,
    required String outputPath,
    required String format, // 'xdelta' | 'ips' | 'ips32' | 'bps' | 'ups' | 'ebp'
  }) async {
    try {
      return await compute(_buildPatchIsolate, {
        'originalPath': originalPath,
        'modifiedPath': modifiedPath,
        'outputPath': outputPath,
        'format': format,
      });
    } on PatchException catch (e) {
      throw OpenROMException(OpenROMError.conversionFailed, details: e.message);
    } catch (e) {
      if (e is OpenROMException) rethrow;
      final msg = e is PatchException ? e.message : e.toString();
      throw OpenROMException(OpenROMError.conversionFailed, details: msg);
    }
  }
}
