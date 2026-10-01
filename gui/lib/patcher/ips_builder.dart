// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';
import 'dart:typed_data';

import 'patcher.dart';

/// Pure Dart IPS (International Patching System) patch creator.
class IpsBuilder {
  final File originalFile;
  final File modifiedFile;
  final File outputFile;

  static const int _maxSize = 0xFFFFFF; // 16MB (16,777,215 bytes)

  IpsBuilder({
    required this.originalFile,
    required this.modifiedFile,
    required this.outputFile,
  });

  Future<void> build() async {
    final origLen = await originalFile.length();
    final modLen = await modifiedFile.length();

    if (origLen > _maxSize || modLen > _maxSize) {
      throw PatchException('File too large for IPS format. Use xdelta instead.');
    }

    final origBytes = await originalFile.readAsBytes();
    final modBytes = await modifiedFile.readAsBytes();

    final builder = BytesBuilder();
    // Magic header "PATCH"
    builder.add([0x50, 0x41, 0x54, 0x43, 0x48]);

    int pos = 0;
    final int targetLen = modBytes.length;

    while (pos < targetLen) {
      // Find next mismatch
      if (pos < origBytes.length && modBytes[pos] == origBytes[pos]) {
        pos++;
        continue;
      }

      int offset = pos;
      // Handle collision with EOF magic (0x454F46)
      if (offset == 0x454F46) {
        if (offset > 0) {
          offset--;
        }
      }

      // Collect contiguous modified bytes (up to 65535)
      int end = offset;
      while (end < targetLen && (end - offset) < 0xFFFF) {
        if (end < origBytes.length && modBytes[end] == origBytes[end]) {
          bool keepGoing = false;
          int lookahead = 1;
          while (lookahead < 3 && (end + lookahead) < targetLen) {
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

      int recordLen = end - offset;
      if (recordLen <= 0) {
        pos = end + 1;
        continue;
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

      // Write 3-byte offset
      builder.addByte((offset >> 16) & 0xFF);
      builder.addByte((offset >> 8) & 0xFF);
      builder.addByte(offset & 0xFF);

      if (isRle) {
        // Size = 0x0000
        builder.addByte(0x00);
        builder.addByte(0x00);
        // RLE Size (2 bytes)
        builder.addByte((recordLen >> 8) & 0xFF);
        builder.addByte(recordLen & 0xFF);
        // Value (1 byte)
        builder.addByte(modBytes[offset]);
      } else {
        // Size (2 bytes)
        builder.addByte((recordLen >> 8) & 0xFF);
        builder.addByte(recordLen & 0xFF);
        // Data
        builder.add(modBytes.sublist(offset, end));
      }

      pos = end;
    }

    // Write "EOF"
    builder.add([0x45, 0x4F, 0x46]);

    await outputFile.writeAsBytes(builder.takeBytes());
  }
}
