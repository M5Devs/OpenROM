// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:io';

import '../models/rom_file.dart';
import 'core_bridge.dart';

class FileDetector {
  static Future<List<RomFile>> detectPaths(List<String> paths) async {
    final List<RomFile> results = [];
    for (final path in paths) {
      if (FileSystemEntity.isFileSync(path)) {
        var rom = await CoreBridge.detectFile(path);
        if (rom != null) {
          final size = File(path).statSync().size;
          rom = RomFile(
            filepath: rom.filepath,
            filename: rom.filename,
            format: rom.format,
            platform: rom.platform,
            sizeBytes: rom.sizeBytes,
            sizeStr: rom.sizeStr,
            validTargets: rom.validTargets,
            badgeColor: rom.badgeColor,
            needsEcmDecode: rom.needsEcmDecode,
            pairedCue: rom.pairedCue,
            pairedBin: rom.pairedBin,
            chdType: rom.chdType,
            fileSizeBytes: size,
          );
          results.add(rom);
        }
      } else if (FileSystemEntity.isDirectorySync(path)) {
        final dir = Directory(path);
        await for (final entity in dir.list(followLinks: false)) {
          if (entity is File) {
            var rom = await CoreBridge.detectFile(entity.path);
            if (rom != null && rom.format != 'UNKNOWN') {
              final size = File(entity.path).statSync().size;
              rom = RomFile(
                filepath: rom.filepath,
                filename: rom.filename,
                format: rom.format,
                platform: rom.platform,
                sizeBytes: rom.sizeBytes,
                sizeStr: rom.sizeStr,
                validTargets: rom.validTargets,
                badgeColor: rom.badgeColor,
                needsEcmDecode: rom.needsEcmDecode,
                pairedCue: rom.pairedCue,
                pairedBin: rom.pairedBin,
                chdType: rom.chdType,
                fileSizeBytes: size,
              );
              results.add(rom);
            }
          }
        }
      }
    }
    return results;
  }
}
