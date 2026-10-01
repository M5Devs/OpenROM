// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';
import 'dart:typed_data';

import 'checksums.dart';
import 'patcher.dart';

/// Pure Dart UPS (Universal Patch System) patch creator.
class UpsBuilder {
  final File originalFile;
  final File modifiedFile;
  final File outputFile;

  UpsBuilder({
    required this.originalFile,
    required this.modifiedFile,
    required this.outputFile,
  });

  Future<void> build() async {
    final origBytes = await originalFile.readAsBytes();
    final modBytes = await modifiedFile.readAsBytes();

    final builder = BytesBuilder();

    // Magic header "UPS1"
    builder.add([0x55, 0x50, 0x53, 0x31]);

    final origLen = origBytes.length;
    final modLen = modBytes.length;

    // Header size fields
    _encodeNumber(builder, origLen);
    _encodeNumber(builder, modLen);

    int currentOffset = 0;
    int i = 0;

    while (i < modLen) {
      final origByte = i < origLen ? origBytes[i] : 0;
      final modByte = modBytes[i];
      final xorVal = origByte ^ modByte;

      if (xorVal == 0) {
        i++;
        continue;
      }

      // Found start of XOR-different region
      final relOffset = i - currentOffset;
      _encodeNumber(builder, relOffset);

      currentOffset = i;

      // Write XOR payload bytes until matching byte or end of target
      while (i < modLen) {
        final oByte = i < origLen ? origBytes[i] : 0;
        final mByte = modBytes[i];
        final x = oByte ^ mByte;
        if (x == 0) break;
        builder.addByte(x);
        i++;
        currentOffset++;
      }

      // Write 0x00 terminator
      builder.addByte(0x00);
      currentOffset++;
    }

    // Footer CRC32s (LE32)
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
