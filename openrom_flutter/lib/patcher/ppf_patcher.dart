// SPDX-License-Identifier: GPL-3.0-or-later
// Ported from Final ROM (https://github.com/eon-com/final_rom) and
// UniPatcher (https://github.com/btimofeev/UniPatcher) — both GPL v3.
// Adapted for OpenROM by M5 Dev.
import 'dart:io';
import 'dart:typed_data';
import 'patcher.dart';
import 'patch_io.dart';

/// PPF (Playstation Patch Format) patcher, supporting versions 1, 2 and 3.
/// Ported from UniPatcher's `PPF.java`.
///
/// PPF patches a copy of the ROM in place: the ROM is first streamed into the
/// output file, then individual chunks are overwritten at absolute offsets.
class PpfPatcher extends RomPatcher {
  PpfPatcher({
    required super.patchFile,
    required super.romFile,
    required super.outputFile,
  });

  static const List<int> _magic = [0x50, 0x50, 0x46]; // "PPF"
  static const List<int> _dizMagic = [0x2E, 0x44, 0x49, 0x5A]; // ".DIZ"

  @override
  Future<PatchReport> apply({bool ignoreChecksum = false}) async {
    final patchLen = await patchFile.length();
    if (patchLen < 61) {
      throw PatchException("Patch file is too small or corrupted.");
    }

    final version = await _getVersion();

    RandomAccessFile? patch;
    RandomAccessFile? output;
    List<PatchCheck> checks;
    try {
      // Seed the output with a full copy of the ROM, then patch it in place.
      final rom = await romFile.open(mode: FileMode.read);
      output = await outputFile.open(mode: FileMode.write);
      await copyWholeFile(rom, output);
      await rom.close();

      patch = await patchFile.open(mode: FileMode.read);
      final romLength = await romFile.length();

      switch (version) {
        case 1:
          checks = await _applyPpf1(patch, output, patchLen);
          break;
        case 2:
          checks = await _applyPpf2(
              patch, output, patchLen, romLength, ignoreChecksum);
          break;
        case 3:
          checks = await _applyPpf3(patch, output, patchLen, ignoreChecksum);
          break;
        default:
          throw PatchException("Not a valid PPF patch.");
      }
    } finally {
      await patch?.close();
      await output?.close();
    }

    return PatchReport(format: "PPF", checks: checks);
  }

  Future<int> _getVersion() async {
    final raf = await patchFile.open(mode: FileMode.read);
    try {
      final header = await raf.read(4);
      if (header.length < 4 ||
          header[0] != _magic[0] ||
          header[1] != _magic[1] ||
          header[2] != _magic[2]) {
        return 0;
      }
      switch (header[3]) {
        case 0x31:
          return 1;
        case 0x32:
          return 2;
        case 0x33:
          return 3;
        default:
          return 0;
      }
    } finally {
      await raf.close();
    }
  }

  /// PPF v1 carries no ROM-compatibility checks.
  Future<List<PatchCheck>> _applyPpf1(
      RandomAccessFile patch, RandomAccessFile output, int dataEnd) async {
    await patch.setPosition(56);
    while (await patch.position() < dataEnd) {
      final offset = await _readLEUint32(patch);
      final chunkSize = await patch.readByte();
      if (chunkSize <= 0) break;
      final chunk = await _readFull(patch, chunkSize);
      await output.setPosition(offset);
      await output.writeFrom(chunk);
    }
    return const [];
  }

  Future<List<PatchCheck>> _applyPpf2(RandomAccessFile patch,
      RandomAccessFile output,
      int patchLen, int romLength, bool ignoreChecksum) async {
    await patch.setPosition(56);
    final romSize = await _readLEUint32(patch);
    if (!ignoreChecksum && romSize != romLength) {
      throw PatchException("ROM is not compatible with this patch.");
    }

    // Validate the 1 KB binary block at 0x9320.
    final patchBinaryBlock = await _readFull(patch, 1024);
    await output.setPosition(0x9320);
    final romBinaryBlock = await _readFull(output, 1024);
    if (!ignoreChecksum && !_bytesEqual(patchBinaryBlock, romBinaryBlock)) {
      throw PatchException("ROM is not compatible with this patch.");
    }

    final outcome =
        ignoreChecksum ? CheckOutcome.skipped : CheckOutcome.passed;
    final checks = [
      PatchCheck("ROM size", outcome),
      PatchCheck("ROM data block", outcome),
    ];

    int dataEnd = patchLen;
    final sizeFileId = await _getSizeFileId(patch, 2, patchLen);
    if (sizeFileId > 0) {
      dataEnd -= (18 + sizeFileId + 16 + 4);
    }

    await patch.setPosition(1084);
    while (await patch.position() < dataEnd) {
      final offset = await _readLEUint32(patch);
      final chunkSize = await patch.readByte();
      if (chunkSize <= 0) break;
      final chunk = await _readFull(patch, chunkSize);
      await output.setPosition(offset);
      await output.writeFrom(chunk);
    }
    return checks;
  }

  Future<List<PatchCheck>> _applyPpf3(RandomAccessFile patch,
      RandomAccessFile output,
      int patchLen, bool ignoreChecksum) async {
    await patch.setPosition(56);
    final imageType = await patch.readByte();
    final blockCheck = await patch.readByte();
    final undo = await patch.readByte();

    final checks = <PatchCheck>[];
    if (blockCheck == 0x01) {
      await patch.setPosition(60);
      await output.setPosition(imageType == 0x01 ? 0x80A0 : 0x9320);
      final patchBinaryBlock = await _readFull(patch, 1024);
      final romBinaryBlock = await _readFull(output, 1024);
      if (!ignoreChecksum && !_bytesEqual(patchBinaryBlock, romBinaryBlock)) {
        throw PatchException("ROM is not compatible with this patch.");
      }
      checks.add(PatchCheck("ROM data block",
          ignoreChecksum ? CheckOutcome.skipped : CheckOutcome.passed));
    }

    int dataEnd = patchLen;
    final sizeFileId = await _getSizeFileId(patch, 3, patchLen);
    if (sizeFileId > 0) {
      dataEnd -= (18 + sizeFileId + 16 + 2);
    }

    await patch.setPosition(blockCheck == 0x01 ? 1084 : 60);
    while (await patch.position() < dataEnd) {
      final offset = await _readLEUint64(patch);
      final chunkSize = await patch.readByte();
      if (chunkSize <= 0) break;
      final chunk = await _readFull(patch, chunkSize);
      if (undo == 0x01) {
        // Skip the embedded undo data that follows the patch data.
        await patch.setPosition(await patch.position() + chunkSize);
      }
      await output.setPosition(offset);
      await output.writeFrom(chunk);
    }
    return checks;
  }

  /// Returns the size of the trailing FileID (.DIZ) block, or 0 if absent.
  Future<int> _getSizeFileId(
      RandomAccessFile patch, int ppfVersion, int patchLen) async {
    if (ppfVersion == 2) {
      await patch.setPosition(patchLen - 4 - 4);
    } else {
      await patch.setPosition(patchLen - 2 - 4);
    }
    final buffer = await _readFull(patch, 4);
    if (!_bytesEqual(buffer, _dizMagic)) {
      return 0;
    }
    int result;
    if (ppfVersion == 2) {
      result = await _readLEUint32(patch);
    } else {
      result = (await patch.readByte()) + ((await patch.readByte()) << 8);
    }
    if (result > 3072) result = 3072;
    return result;
  }

  Future<int> _readLEUint32(RandomAccessFile raf) async {
    final b = await _readFull(raf, 4);
    return b[0] | (b[1] << 8) | (b[2] << 16) | (b[3] << 24);
  }

  Future<int> _readLEUint64(RandomAccessFile raf) async {
    final b = await _readFull(raf, 8);
    return b[0] |
        (b[1] << 8) |
        (b[2] << 16) |
        (b[3] << 24) |
        (b[4] << 32) |
        (b[5] << 40) |
        (b[6] << 48) |
        (b[7] << 56);
  }

  /// Reads exactly [count] bytes, looping until satisfied or EOF.
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

  bool _bytesEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
