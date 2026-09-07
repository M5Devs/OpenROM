// SPDX-License-Identifier: GPL-3.0-or-later
// Ported from Final ROM (https://github.com/eon-com/final_rom) and
// UniPatcher (https://github.com/btimofeev/UniPatcher) — both GPL v3.
// Adapted for OpenROM by M5 Dev.
import 'dart:io';
import 'dart:typed_data';
import 'patcher.dart';
import 'checksums.dart';
import 'patch_io.dart';

/// APS patcher for the GBA variant (magic "APS1"). Ported from UniPatcher's
/// `APS_GBA.java`.
///
/// The patch is a series of 64 KB XOR blocks, each guarded by two CRC-16
/// values identifying the original and already-patched ROM. This lets the same
/// patch detect whether the ROM is unpatched (apply) and produce the correct
/// final size.
class ApsGbaPatcher extends RomPatcher {
  ApsGbaPatcher({
    required super.patchFile,
    required super.romFile,
    required super.outputFile,
  });

  static const List<int> _magic = [0x41, 0x50, 0x53, 0x31]; // "APS1"
  static const int _chunkSize = 65536;

  @override
  Future<PatchReport> apply({bool ignoreChecksum = false}) async {
    final patchLen = await patchFile.length();

    RandomAccessFile? patch;
    RandomAccessFile? output;
    bool isOriginal = false;
    bool isModified = false;
    int fileSize1, fileSize2;

    try {
      final rom = await romFile.open(mode: FileMode.read);
      output = await outputFile.open(mode: FileMode.write);
      await copyWholeFile(rom, output);
      await rom.close();

      patch = await patchFile.open(mode: FileMode.read);

      final magic = await patch.read(4);
      if (magic.length < 4 || !_bytesEqual(magic, _magic)) {
        throw PatchException("Not a valid APS patch.");
      }

      fileSize1 = await _readLEUint32(patch);
      fileSize2 = await _readLEUint32(patch);

      int bytesLeft = patchLen - 12;
      while (bytesLeft > 0) {
        final offset = await _readLEUint32(patch);
        final patchCrc1 = await _readLEUint16(patch);
        final patchCrc2 = await _readLEUint16(patch);
        bytesLeft -= 8;

        await output.setPosition(offset);
        final romChunk = await _readUpTo(output, _chunkSize);
        final patchChunk = await _readFull(patch, _chunkSize);
        bytesLeft -= _chunkSize;
        if (patchChunk.length < _chunkSize) {
          throw PatchException("Not a valid APS patch.");
        }

        // Pad the ROM block with zeros if it runs past the end of the file.
        final romBuf = Uint8List(_chunkSize);
        romBuf.setRange(0, romChunk.length, romChunk);

        final crc = Crc16.calculate(romBuf);

        for (int i = 0; i < _chunkSize; i++) {
          romBuf[i] ^= patchChunk[i];
        }

        if (crc == patchCrc1) {
          isOriginal = true;
        } else if (crc == patchCrc2) {
          isModified = true;
        } else {
          if (!ignoreChecksum) {
            throw PatchException("ROM is not compatible with this patch.");
          }
        }
        if (isOriginal && isModified) {
          throw PatchException("Not a valid APS patch.");
        }

        await output.setPosition(offset);
        await output.writeFrom(romBuf);
      }

      if (isOriginal) {
        await output.truncate(fileSize2);
      } else if (isModified) {
        await output.truncate(fileSize1);
      }
    } finally {
      await patch?.close();
      await output?.close();
    }

    return PatchReport(format: "APS", checks: [
      PatchCheck("ROM (CRC16)",
          ignoreChecksum ? CheckOutcome.skipped : CheckOutcome.passed),
    ]);
  }

  Future<int> _readLEUint32(RandomAccessFile raf) async {
    final b = await _readFull(raf, 4);
    return b[0] | (b[1] << 8) | (b[2] << 16) | (b[3] << 24);
  }

  Future<int> _readLEUint16(RandomAccessFile raf) async {
    final b = await _readFull(raf, 2);
    return b[0] | (b[1] << 8);
  }

  Future<Uint8List> _readFull(RandomAccessFile raf, int count) async {
    final out = Uint8List(count);
    int filled = 0;
    while (filled < count) {
      final chunk = await raf.read(count - filled);
      if (chunk.isEmpty) break;
      out.setRange(filled, filled + chunk.length, chunk);
      filled += chunk.length;
    }
    return filled == count ? out : Uint8List.sublistView(out, 0, filled);
  }

  Future<Uint8List> _readUpTo(RandomAccessFile raf, int count) async {
    return raf.read(count);
  }

  bool _bytesEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
