// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;

final Uint8List _cdSync = Uint8List.fromList([
  0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00
]);

bool _sublistEquals(Uint8List list, int offset, Uint8List sublist) {
  if (offset < 0 || offset + sublist.length > list.length) return false;
  for (int i = 0; i < sublist.length; i++) {
    if (list[offset + i] != sublist[i]) return false;
  }
  return true;
}

String detectBinMode(String binPath) {
  try {
    final file = File(binPath);
    final raf = file.openSync(mode: FileMode.read);
    final header = raf.readSync(32);
    raf.closeSync();

    if (header.length >= 16) {
      if (_sublistEquals(header, 0, _cdSync)) {
        final modeByte = header[15];
        if (modeByte == 1) return 'MODE1/2352';
        if (modeByte == 2) return 'MODE2/2352';
      }
      if (_sublistEquals(header, 16, _cdSync)) {
        return 'MODE2/2352';
      }
    }
  } catch (_) {}

  try {
    final size = File(binPath).lengthSync();
    if (size % 2352 == 0) return 'MODE2/2352';
    if (size % 2048 == 0) return 'MODE1/2048';
  } catch (_) {}

  return 'MODE2/2352';
}

String generateCue(String binPath, {String? outputDir}) {
  final file = File(binPath);
  if (!file.existsSync()) {
    throw FileSystemException('BIN file not found: $binPath', binPath);
  }

  final targetDir = (outputDir != null && outputDir.isNotEmpty)
      ? outputDir
      : p.dirname(p.canonicalize(binPath));
  Directory(targetDir).createSync(recursive: true);

  final binName = p.basename(binPath);
  final idx = binName.lastIndexOf('.');
  final baseStem = idx != -1 ? binName.substring(0, idx) : binName;
  final cuePath = p.join(targetDir, '$baseStem.cue');

  final trackMode = detectBinMode(binPath);

  final cueContent = StringBuffer();
  cueContent.writeln('FILE "$binName" BINARY');
  cueContent.writeln('  TRACK 01 $trackMode');
  cueContent.writeln('    INDEX 01 00:00:00');

  File(cuePath).writeAsStringSync(cueContent.toString());
  return cuePath;
}
