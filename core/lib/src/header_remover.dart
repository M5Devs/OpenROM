// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;

const Map<String, Map<String, dynamic>> supportedHeaders = {
  'NES': {
    'magic': [0x4E, 0x45, 0x53, 0x1A],
    'size': 16,
    'ext': ['.nes']
  },
  'SNES': {
    'size': 512,
    'ext': ['.smc', '.sfc', '.fig', '.swc']
  },
  'GB/GBC': {
    'size': 512,
    'ext': ['.gb', '.gbc']
  },
  'GBA': {
    'size': 0,
    'ext': ['.gba']
  },
};

bool _verifySnesInternalHeader(Uint8List data, int offset) {
  if (data.length < offset + 0x40) {
    return false;
  }
  final complement = data[offset + 0x1C] | (data[offset + 0x1D] << 8);
  final checksum = data[offset + 0x1E] | (data[offset + 0x1F] << 8);

  if ((checksum ^ complement) == 0xFFFF && complement != 0) {
    return true;
  }
  return false;
}

Map<String, dynamic>? detectHeader(String filepath) {
  final file = File(filepath);
  if (!file.existsSync()) return null;

  final ext = p.extension(filepath).toLowerCase();
  String? system;

  for (final entry in supportedHeaders.entries) {
    final list = entry.value['ext'] as List<String>;
    if (list.contains(ext)) {
      system = entry.key;
      break;
    }
  }

  if (system == null) return null;

  final fileSize = file.lengthSync();

  if (system == 'NES') {
    try {
      final raf = file.openSync(mode: FileMode.read);
      final magic = raf.readSync(4);
      raf.closeSync();
      if (magic.length == 4 &&
          magic[0] == 0x4E &&
          magic[1] == 0x45 &&
          magic[2] == 0x53 &&
          magic[3] == 0x1A) {
        return {
          'system': 'NES',
          'header_size': 16,
          'has_header': true,
          'confidence': 'certain'
        };
      } else {
        return {
          'system': 'NES',
          'header_size': 0,
          'has_header': false,
          'confidence': 'certain'
        };
      }
    } catch (_) {
      return null;
    }
  } else if (system == 'SNES') {
    final rem = fileSize % 1024;
    try {
      final raf = file.openSync(mode: FileMode.read);
      final headerData = raf.readSync(0x10200);
      raf.closeSync();

      final hasCopierHeaderInternal =
          _verifySnesInternalHeader(headerData, 0x81C0) ||
              _verifySnesInternalHeader(headerData, 0x101C0);
      final hasCleanInternal =
          _verifySnesInternalHeader(headerData, 0x7FC0) ||
              _verifySnesInternalHeader(headerData, 0xFFC0);

      if (hasCopierHeaderInternal) {
        return {
          'system': 'SNES',
          'header_size': 512,
          'has_header': true,
          'confidence': 'certain'
        };
      } else if (hasCleanInternal) {
        return {
          'system': 'SNES',
          'header_size': 0,
          'has_header': false,
          'confidence': 'certain'
        };
      }
    } catch (_) {}

    if (rem == 512) {
      return {
        'system': 'SNES',
        'header_size': 512,
        'has_header': true,
        'confidence': 'likely'
      };
    } else if (rem == 0) {
      return {
        'system': 'SNES',
        'header_size': 0,
        'has_header': false,
        'confidence': 'certain'
      };
    } else {
      return {
        'system': 'SNES',
        'header_size': 0,
        'has_header': false,
        'confidence': 'unlikely'
      };
    }
  } else if (system == 'GB/GBC') {
    final rem = fileSize % 1024;
    if (rem == 512) {
      return {
        'system': 'GB/GBC',
        'header_size': 512,
        'has_header': true,
        'confidence': 'certain'
      };
    } else if (rem == 0) {
      return {
        'system': 'GB/GBC',
        'header_size': 0,
        'has_header': false,
        'confidence': 'certain'
      };
    } else {
      return {
        'system': 'GB/GBC',
        'header_size': 0,
        'has_header': false,
        'confidence': 'likely'
      };
    }
  } else if (system == 'GBA') {
    return {
      'system': 'GBA',
      'header_size': 0,
      'has_header': false,
      'confidence': 'certain'
    };
  }

  return null;
}

String removeHeader(
  String filepath, {
  String? outputDir,
  bool backup = true,
}) {
  final file = File(filepath);
  if (!file.existsSync()) {
    throw FileSystemException('ROM file not found: $filepath', filepath);
  }

  final info = detectHeader(filepath);
  final targetDir = (outputDir != null && outputDir.isNotEmpty)
      ? outputDir
      : p.dirname(p.canonicalize(filepath));
  Directory(targetDir).createSync(recursive: true);

  final filename = p.basename(filepath);
  final cleanPath = p.join(targetDir, filename);

  if (backup && p.canonicalize(cleanPath) == p.canonicalize(filepath)) {
    final bakPath = '$filepath.bak';
    if (!File(bakPath).existsSync()) {
      file.copySync(bakPath);
    }
  }

  if (info == null ||
      info['has_header'] != true ||
      (info['header_size'] as int? ?? 0) <= 0) {
    if (p.canonicalize(cleanPath) != p.canonicalize(filepath)) {
      file.copySync(cleanPath);
    }
    return cleanPath;
  }

  final hdrSize = info['header_size'] as int;

  final inRaf = file.openSync(mode: FileMode.read);
  inRaf.setPositionSync(hdrSize);

  final outSink = File(cleanPath).openSync(mode: FileMode.write);
  const chunkSize = 1024 * 1024;
  while (true) {
    final chunk = inRaf.readSync(chunkSize);
    if (chunk.isEmpty) break;
    outSink.writeFromSync(chunk);
  }
  inRaf.closeSync();
  outSink.closeSync();

  return cleanPath;
}
