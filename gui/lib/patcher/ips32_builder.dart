// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';
import 'dart:typed_data';

import 'patcher.dart';

/// Pure Dart IPS32 patch creator.
class IPS32Builder {
  final File originalFile;
  final File modifiedFile;
  final File outputFile;

  IPS32Builder({
    required this.originalFile,
    required this.modifiedFile,
    required this.outputFile,
  });

  Future<void> build() async {
    final origBytes = await originalFile.readAsBytes();
    final modBytes = await modifiedFile.readAsBytes();

    final builder = BytesBuilder();
    // Magic header "IPS32"
    builder.add([0x49, 0x50, 0x53, 0x33, 0x32]);

    int pos = 0;
    final int targetLen = modBytes.length;

    while (pos < targetLen) {
      // Find next mismatch
      if (pos < origBytes.length && modBytes[pos] == origBytes[pos]) {
        pos++;
        continue;
      }

      int offset = pos;
      // Handle collision with EEOF magic (0x45454F46)
      if (offset == 0x45454F46) {
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

      // Write 4-byte offset
      builder.addByte((offset >> 24) & 0xFF);
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

    // Write "EEOF"
    builder.add([0x45, 0x45, 0x4F, 0x46]);

    await outputFile.writeAsBytes(builder.takeBytes());
  }
}
