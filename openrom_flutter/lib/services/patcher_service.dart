// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3 + Commons Clause

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
}
