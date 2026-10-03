// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';
import 'dart:typed_data';

/// Pure Dart PPF3 (Playstation Patch Format v3) patch creator.
class PpfBuilder {
  final File originalFile;
  final File modifiedFile;
  final File outputFile;
  final String description;
  final int imageType; // 0 = CD, 1 = DVD

  PpfBuilder({
    required this.originalFile,
    required this.modifiedFile,
    required this.outputFile,
    this.description = 'Created with OpenROM',
    this.imageType = 0,
  });

  Future<void> build() async {
    final origBytes = await originalFile.readAsBytes();
    final modBytes = await modifiedFile.readAsBytes();

    final builder = BytesBuilder();

    // 1. Header (60 bytes)
    // [0..2] "PPF"
    builder.add([0x50, 0x50, 0x46]);
    // [3] '3' (0x33)
    builder.addByte(0x33);

    // [4..51] Description (48 bytes, null-padded)
    final descBytes = Uint8List(48);
    final descAscii = description.codeUnits;
    for (int i = 0; i < descAscii.length && i < 48; i++) {
      descBytes[i] = descAscii[i];
    }
    builder.add(descBytes);

    // [52] Image type (0x00 = CD, 0x01 = DVD)
    builder.addByte(imageType & 0xFF);
    // [53] Block check (0x00 = disabled)
    builder.addByte(0x00);
    // [54] Undo data (0x00 = disabled)
    builder.addByte(0x00);
    // [55] Dummy / padding
    builder.addByte(0x00);
    // [56..59] Reserved / padding (4 bytes)
    builder.add([0x00, 0x00, 0x00, 0x00]);

    // 2. Records
    int pos = 0;
    final int targetLen = modBytes.length;

    while (pos < targetLen) {
      if (pos < origBytes.length && modBytes[pos] == origBytes[pos]) {
        pos++;
        continue;
      }

      final offset = pos;
      int end = offset;
      while (end < targetLen && (end - offset) < 255) {
        if (end < origBytes.length && modBytes[end] == origBytes[end]) {
          // Check lookahead
          bool keepGoing = false;
          int lookahead = 1;
          while (lookahead < 4 && (end + lookahead) < targetLen) {
            if ((end + lookahead) >= origBytes.length ||
                modBytes[end + lookahead] != origBytes[end + lookahead]) {
              keepGoing = true;
              break;
            }
            lookahead++;
          }
          if (!keepGoing) break;
        }
        end++;
      }

      final recordLen = end - offset;
      if (recordLen <= 0) {
        pos = end + 1;
        continue;
      }

      // 8-byte LE offset
      for (int i = 0; i < 8; i++) {
        builder.addByte((offset >> (i * 8)) & 0xFF);
      }
      // 1-byte chunk size
      builder.addByte(recordLen & 0xFF);
      // Data bytes
      builder.add(modBytes.sublist(offset, end));

      pos = end;
    }

    await outputFile.writeAsBytes(builder.takeBytes());
  }
}
