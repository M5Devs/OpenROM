// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3 + Commons Clause

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../core/errors.dart';
import '../patcher/patcher.dart';
import '../patcher/patcher_factory.dart';
import 'core_bridge.dart';

/// Top-level function executed inside [compute] isolate.
Future<PatchReport> _applyPatchIsolate(Map<String, dynamic> params) async {
  final romPath = params['romPath'] as String;
  final patchPath = params['patchPath'] as String;
  final outputPath = params['outputPath'] as String;
  final ignoreChecksum = params['ignoreChecksum'] as bool;

  final patcher = PatcherFactory.create(
    patchFile: File(patchPath),
    romFile: File(romPath),
    outputFile: File(outputPath),
  );

  return await patcher.apply(ignoreChecksum: ignoreChecksum);
}

class PatcherService {
  Future<PatchReport> applyPatch({
    required String romPath,
    required String patchPath,
    required String outputPath,
    bool ignoreChecksum = false,
  }) async {
    try {
      return await compute(_applyPatchIsolate, {
        'romPath': romPath,
        'patchPath': patchPath,
        'outputPath': outputPath,
        'ignoreChecksum': ignoreChecksum,
      });
    } on PatchException catch (e) {
      throw OpenROMException(OpenROMError.conversionFailed, details: e.message);
    } catch (e) {
      if (e is OpenROMException) rethrow;
      final msg = e is PatchException ? e.message : e.toString();
      throw OpenROMException(OpenROMError.conversionFailed, details: msg);
    }
  }

  /// Apply an SSP patch using the bundled saturn-patcher binary.
  /// SSP patches the BIN file in-place — no output file is created.
  /// [binPath] must be the Track 1 BIN file of the Saturn disc image.
  Future<String> applySspPatch({
    required String sspPath,
    required String binPath,
  }) async {
    final saturnPatcher = await CoreBridge.getToolPath('saturn-patcher');
    if (saturnPatcher == null || saturnPatcher.isEmpty) {
      throw OpenROMException(
        OpenROMError.toolFailed,
        details: 'saturn-patcher binary not found. Please check your OpenROM installation.',
      );
    }

    if (!File(sspPath).existsSync()) {
      throw OpenROMException(OpenROMError.fileNotFound, details: 'SSP file not found: $sspPath');
    }
    if (!File(binPath).existsSync()) {
      throw OpenROMException(OpenROMError.fileNotFound, details: 'BIN file not found: $binPath');
    }

    try {
      final result = await Process.run(saturnPatcher, [sspPath, binPath]);

      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }

      final err = result.stderr.toString().trim();
      throw OpenROMException(
        OpenROMError.conversionFailed,
        details: err.isNotEmpty ? err : 'saturn-patcher exited with code ${result.exitCode}',
      );
    } on ProcessException catch (e) {
      throw OpenROMException(OpenROMError.toolFailed, details: e.toString());
    } catch (e) {
      if (e is OpenROMException) rethrow;
      throw OpenROMException(OpenROMError.unknownError, details: e.toString());
    }
  }
}
