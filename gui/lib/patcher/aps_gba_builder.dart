// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';
import 'dart:typed_data';

import 'checksums.dart';

/// Pure Dart APS (GBA variant, magic "APS1") patch creator.
class ApsGbaBuilder {
  final File originalFile;
  final File modifiedFile;
  final File outputFile;

  static const int _chunkSize = 65536;

  ApsGbaBuilder({
    required this.originalFile,
    required this.modifiedFile,
    required this.outputFile,
  });

  Future<void> build() async {
    final origBytes = await originalFile.readAsBytes();
    final modBytes = await modifiedFile.readAsBytes();

    final builder = BytesBuilder();

    // Magic "APS1"
    builder.add([0x41, 0x50, 0x53, 0x31]);

    // File sizes (LE Uint32)
    final origLen = origBytes.length;
    final modLen = modBytes.length;

    for (int i = 0; i < 4; i++) {
      builder.addByte((origLen >> (i * 8)) & 0xFF);
    }
    for (int i = 0; i < 4; i++) {
      builder.addByte((modLen >> (i * 8)) & 0xFF);
    }

    final maxLen = origLen > modLen ? origLen : modLen;

    for (int offset = 0; offset < maxLen; offset += _chunkSize) {
      final origChunk = Uint8List(_chunkSize);
      final modChunk = Uint8List(_chunkSize);

      if (offset < origLen) {
        final end = (offset + _chunkSize) < origLen
            ? (offset + _chunkSize)
            : origLen;
        origChunk.setRange(0, end - offset, origBytes.sublist(offset, end));
      }

      if (offset < modLen) {
        final end = (offset + _chunkSize) < modLen
            ? (offset + _chunkSize)
            : modLen;
        modChunk.setRange(0, end - offset, modBytes.sublist(offset, end));
      }

      final patchChunk = Uint8List(_chunkSize);
      bool hasDiff = false;
      for (int i = 0; i < _chunkSize; i++) {
        final xorVal = origChunk[i] ^ modChunk[i];
        patchChunk[i] = xorVal;
        if (xorVal != 0) {
          hasDiff = true;
        }
      }

      if (hasDiff) {
        final origCrc = Crc16.calculate(origChunk);
        final modCrc = Crc16.calculate(modChunk);

        // Offset LE Uint32
        for (int i = 0; i < 4; i++) {
          builder.addByte((offset >> (i * 8)) & 0xFF);
        }
        // Patch CRC1 (Original) LE Uint16
        builder.addByte(origCrc & 0xFF);
        builder.addByte((origCrc >> 8) & 0xFF);
        // Patch CRC2 (Modified) LE Uint16
        builder.addByte(modCrc & 0xFF);
        builder.addByte((modCrc >> 8) & 0xFF);

        // XOR block (64KB)
        builder.add(patchChunk);
      }
    }

    await outputFile.writeAsBytes(builder.takeBytes());
  }
}
