// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';
import 'dart:typed_data';

import 'patcher.dart';

/// Pure Dart APS (N64 variant, magic "APS10") patch creator.
class ApsN64Builder {
  final File originalFile;
  final File modifiedFile;
  final File outputFile;
  final String description;

  ApsN64Builder({
    required this.originalFile,
    required this.modifiedFile,
    required this.outputFile,
    this.description = 'Created with OpenROM',
  });

  Future<void> build() async {
    final origBytes = await originalFile.readAsBytes();
    final modBytes = await modifiedFile.readAsBytes();

    final builder = BytesBuilder();

    // Magic "APS10"
    builder.add([0x41, 0x50, 0x53, 0x31, 0x30]);

    final bool isN64Header = origBytes.length >= 0x40;
    final int patchType = isN64Header ? 1 : 0;
    final int encoding = 0;

    builder.addByte(patchType);
    builder.addByte(encoding);

    // Description (50 bytes, null-padded)
    final descBytes = Uint8List(50);
    final descAscii = description.codeUnits;
    for (int i = 0; i < descAscii.length && i < 50; i++) {
      descBytes[i] = descAscii[i];
    }
    builder.add(descBytes);

    if (isN64Header) {
      final int firstByte = origBytes[0];
      final int endianness = (firstByte == 0x37) ? 0 : 1;

      int cartId;
      if (endianness == 1) {
        cartId = ((origBytes[0x3c] & 0xff) << 8) | (origBytes[0x3d] & 0xff);
      } else {
        cartId = (origBytes[0x3c] & 0xff) | ((origBytes[0x3d] & 0xff) << 8);
      }

      int country;
      if (endianness == 1) {
        country = origBytes[0x3e] & 0xff;
      } else {
        country = origBytes[0x3f] & 0xff;
      }

      final crcBytes = Uint8List.fromList(origBytes.sublist(0x10, 0x18));
      if (endianness == 0) {
        for (int i = 0; i < crcBytes.length; i += 2) {
          final tmp = crcBytes[i];
          crcBytes[i] = crcBytes[i + 1];
          crcBytes[i + 1] = tmp;
        }
      }

      builder.addByte(endianness);
      builder.addByte((cartId >> 8) & 0xff);
      builder.addByte(cartId & 0xff);
      builder.addByte(country & 0xff);
      builder.add(crcBytes);
      builder.add([0x00, 0x00, 0x00, 0x00, 0x00]); // 5 reserved bytes
    }

    // Output size (LE Uint32)
    final modLen = modBytes.length;
    for (int i = 0; i < 4; i++) {
      builder.addByte((modLen >> (i * 8)) & 0xff);
    }

    // Patch records
    int pos = 0;
    final targetLen = modBytes.length;

    while (pos < targetLen) {
      if (pos < origBytes.length && modBytes[pos] == origBytes[pos]) {
        pos++;
        continue;
      }

      final offset = pos;
      int end = offset;
      while (end < targetLen && (end - offset) < 255) {
        if (end < origBytes.length && modBytes[end] == origBytes[end]) {
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

      // Record offset (LE Uint32)
      for (int i = 0; i < 4; i++) {
        builder.addByte((offset >> (i * 8)) & 0xff);
      }

      // Check RLE opportunity
      bool isRle = false;
      if (recordLen >= 8) {
        final val = modBytes[offset];
        isRle = true;
        for (int k = offset + 1; k < end; k++) {
          if (modBytes[k] != val) {
            isRle = false;
            break;
          }
        }
      }

      if (isRle) {
        builder.addByte(0x00); // size = 0 triggers RLE mode in ApsN64Patcher
        builder.addByte(modBytes[offset]); // value
        builder.addByte(recordLen & 0xff); // count
      } else {
        builder.addByte(recordLen & 0xff);
        builder.add(modBytes.sublist(offset, end));
      }

      pos = end;
    }

    await outputFile.writeAsBytes(builder.takeBytes());
  }
}
