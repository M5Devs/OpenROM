// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3 + Commons Clause

import 'dart:io';
import '../models/rom_file.dart';
import 'core_bridge.dart';

class FileDetector {
  static Future<List<RomFile>> detectPaths(List<String> paths) async {
    final List<RomFile> results = [];
    for (final path in paths) {
      if (FileSystemEntity.isFileSync(path)) {
        final rom = await CoreBridge.detectFile(path);
        if (rom != null) {
          results.add(rom);
        }
      } else if (FileSystemEntity.isDirectorySync(path)) {
        final dir = Directory(path);
        await for (final entity in dir.list(followLinks: false)) {
          if (entity is File) {
            final rom = await CoreBridge.detectFile(entity.path);
            if (rom != null && rom.format != 'UNKNOWN') {
              results.add(rom);
            }
          }
        }
      }
    }
    return results;
  }
}
