// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3 + Commons Clause

import '../core/errors.dart';
import 'core_bridge.dart';

class CompressorService {
  Future<void> compressFiles({
    required List<String> files,
    required String format,
    required String level,
    required bool deleteSource,
    String? outputDir,
    ProgressCallback? onProgress,
    LogCallback? onLog,
    DoneCallback? onDone,
  }) async {
    try {
      await CoreBridge.runCompress(
        files: files,
        format: format,
        level: level,
        deleteSource: deleteSource,
        outputDir: outputDir,
        onProgress: onProgress,
        onLog: onLog,
        onDone: onDone,
      );
    } catch (e) {
      if (e is OpenROMException) rethrow;
      throw OpenROMException(OpenROMError.conversionFailed, details: e.toString());
    }
  }

  Future<void> extractFiles({
    required List<String> files,
    required bool deleteSource,
    String? outputDir,
    ProgressCallback? onProgress,
    LogCallback? onLog,
    DoneCallback? onDone,
  }) async {
    try {
      await CoreBridge.runExtract(
        files: files,
        deleteSource: deleteSource,
        outputDir: outputDir,
        onProgress: onProgress,
        onLog: onLog,
        onDone: onDone,
      );
    } catch (e) {
      if (e is OpenROMException) rethrow;
      throw OpenROMException(OpenROMError.conversionFailed, details: e.toString());
    }
  }
}
