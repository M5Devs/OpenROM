// SPDX-License-Identifier: GPL-3.0-or-later
// Ported from Final ROM (https://github.com/eon-com/final_rom) and
// UniPatcher (https://github.com/btimofeev/UniPatcher) — both GPL v3.
// Adapted for OpenROM by M5 Dev.
import 'dart:io';
import 'dart:typed_data';
import 'package:openrom_flutter/patcher/io_tuning.dart';
import 'patcher.dart';

class IpsPatcher extends RomPatcher {
  IpsPatcher({
    required super.patchFile,
    required super.romFile,
    required super.outputFile,
  });

  @override
  Future<PatchReport> apply({bool ignoreChecksum = false}) async {
    final patchLen = await patchFile.length();
    if (patchLen < 14) {
      throw PatchException("Patch file is too small or corrupted.");
    }

    RandomAccessFile? rom;
    RandomAccessFile? patch;
    RandomAccessFile? output;
    String format = "IPS";

    try {
      rom = await romFile.open(mode: FileMode.read);
      patch = await patchFile.open(mode: FileMode.read);
      output = await outputFile.open(mode: FileMode.write);

      final magic = await patch.read(5);
      final isIps32 = _isIps32(magic);
      if (!isIps32 && !_isIps(magic)) {
        throw PatchException("Not a valid IPS patch.");
      }
      format = isIps32 ? "IPS32" : "IPS";

      final romSize = await romFile.length();
      int romPos = 0;
      int outPos = 0;

      while (true) {
        final offset = await _readOffset(patch, isIps32);
        if (_isEOF(offset, isIps32)) {
          // Truncate or copy tail
          if (romPos < romSize) {
            final truncateOffset = await _readOffset(patch, isIps32);
            int tailSize;
            if (truncateOffset != -1 && truncateOffset >= romPos) {
              tailSize = truncateOffset - romPos;
            } else {
              tailSize = romSize - romPos;
            }
            await _copy(rom, output, tailSize);
          }
          break;
        }

        if (offset <= romSize) {
          if (outPos < offset) {
            final size = offset - outPos;
            await _copy(rom, output, size);
            romPos += size;
            outPos += size;
          }
        } else {
          if (outPos < romSize) {
            final size = romSize - outPos;
            await _copy(rom, output, size);
            romPos += size;
            outPos += size;
          }
          if (outPos < offset) {
            final size = offset - outPos;
            await _copyValue(output, size, 0);
            outPos += size;
          }
        }

        int b1 = await patch.readByte();
        int b2 = await patch.readByte();
        if (b1 == -1 || b2 == -1) break;
        int size = (b1 << 8) + b2;

        if (size == 0) { // RLE
          b1 = await patch.readByte();
          b2 = await patch.readByte();
          size = (b1 << 8) + b2;
          int value = await patch.readByte();
          await _copyValue(output, size, value);
          outPos += size;
        } else {
          await _copy(patch, output, size);
          outPos += size;
        }

        if (offset <= romSize) {
          if (romPos + size > romSize) {
            romPos = romSize;
          } else {
            await rom.setPosition(romPos + size);
            romPos += size;
          }
        }
      }
    } finally {
      await rom?.close();
      await patch?.close();
      await output?.close();
    }

    // IPS carries no embedded checksums, so there is nothing to verify.
    return PatchReport(format: format);
  }

  bool _isIps(Uint8List magic) => 
      magic.length == 5 && magic[0]==0x50 && magic[1]==0x41 && magic[2]==0x54 && magic[3]==0x43 && magic[4]==0x48; // "PATCH"

  bool _isIps32(Uint8List magic) => 
      magic.length == 5 && magic[0]==0x49 && magic[1]==0x50 && magic[2]==0x53 && magic[3]==0x33 && magic[4]==0x32; // "IPS32"

  bool _isEOF(int offset, bool isIps32) {
    if (isIps32) return offset == 0x45454f46; // EEOF
    return offset == 0x454f46; // EOF
  }

  Future<int> _readOffset(RandomAccessFile stream, bool isIps32) async {
    int numBytes = isIps32 ? 4 : 3;
    int offset = 0;
    for (int i = 0; i < numBytes; i++) {
      int b = await stream.readByte();
      if (b == -1) return -1;
      offset = (offset << 8) + b;
    }
    return offset;
  }

  Future<void> _copy(RandomAccessFile from, RandomAccessFile to, int size) async {
    int remaining = size;
    const bufferSize = patchCopyBufferSize;
    while (remaining > 0) {
      int toRead = remaining > bufferSize ? bufferSize : remaining;
      final bytes = await from.read(toRead);
      if (bytes.isEmpty) break;
      await to.writeFrom(bytes);
      remaining -= bytes.length;
    }
  }

  Future<void> _copyValue(RandomAccessFile to, int size, int value) async {
    int remaining = size;
    const bufferSize = patchCopyBufferSize;
    final chunk = Uint8List(bufferSize);
    chunk.fillRange(0, bufferSize, value);
    while (remaining > 0) {
      int toWrite = remaining > bufferSize ? bufferSize : remaining;
      await to.writeFrom(chunk, 0, toWrite);
      remaining -= toWrite;
    }
  }
}
