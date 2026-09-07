// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3 + Commons Clause

import '../core/errors.dart';
import 'core_bridge.dart';

class M3UService {
  Future<String> generateM3u({
    required List<String> discFiles,
    required String outputDir,
    bool relative = true,
  }) async {
    try {
      return await CoreBridge.generateM3u(
        discFiles: discFiles,
        outputDir: outputDir,
        relative: relative,
      );
    } catch (e) {
      if (e is OpenROMException) rethrow;
      throw OpenROMException(OpenROMError.conversionFailed, details: e.toString());
    }
  }
}
