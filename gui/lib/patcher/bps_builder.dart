// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';
import 'dart:typed_data';

import 'checksums.dart';

/// Pure Dart BPS (Binary Patch System) patch creator.
class BpsBuilder {
  final File originalFile;
  final File modifiedFile;
  final File outputFile;

  BpsBuilder({
    required this.originalFile,
    required this.modifiedFile,
    required this.outputFile,
  });

  Future<void> build() async {
    final origBytes = await originalFile.readAsBytes();
    final modBytes = await modifiedFile.readAsBytes();

    final builder = BytesBuilder();

    // Magic header "BPS1"
    builder.add([0x42, 0x50, 0x53, 0x31]);

    // Header fields
    _encodeNumber(builder, origBytes.length);
    _encodeNumber(builder, modBytes.length);
    _encodeNumber(builder, 0); // metadata length = 0

    int pos = 0;
    final int modLen = modBytes.length;
    final int origLen = origBytes.length;

    while (pos < modLen) {
      // Find length of matching bytes (SOURCE_READ mode)
      int matchLen = 0;
      while ((pos + matchLen) < modLen &&
          (pos + matchLen) < origLen &&
          modBytes[pos + matchLen] == origBytes[pos + matchLen]) {
        matchLen++;
      }

      if (matchLen > 0) {
        final action = ((matchLen - 1) << 2) | 0; // Mode 0 = SOURCE_READ
        _encodeNumber(builder, action);
        pos += matchLen;
      }

      if (pos < modLen) {
        // Find length of differing bytes (TARGET_READ mode)
        int diffLen = 0;
        while ((pos + diffLen) < modLen &&
            ((pos + diffLen) >= origLen ||
                modBytes[pos + diffLen] != origBytes[pos + diffLen])) {
          diffLen++;
        }

        if (diffLen > 0) {
          final action = ((diffLen - 1) << 2) | 1; // Mode 1 = TARGET_READ
          _encodeNumber(builder, action);
          builder.add(modBytes.sublist(pos, pos + diffLen));
          pos += diffLen;
        }
      }
    }

    final sourceCrc = crc32Bytes(origBytes);
    final targetCrc = crc32Bytes(modBytes);

    _addUint32LE(builder, sourceCrc);
    _addUint32LE(builder, targetCrc);

    final partialPatch = builder.toBytes();
    final patchCrc = crc32Bytes(partialPatch);

    _addUint32LE(builder, patchCrc);

    await outputFile.writeAsBytes(builder.takeBytes());
  }

  void _encodeNumber(BytesBuilder builder, int value) {
    int data = value;
    while (true) {
      int x = data & 0x7f;
      data >>= 7;
      if (data == 0) {
        builder.addByte(x | 0x80);
        break;
      }
      builder.addByte(x);
      data--;
    }
  }

  void _addUint32LE(BytesBuilder builder, int value) {
    builder.addByte(value & 0xFF);
    builder.addByte((value >> 8) & 0xFF);
    builder.addByte((value >> 16) & 0xFF);
    builder.addByte((value >> 24) & 0xFF);
  }
}
