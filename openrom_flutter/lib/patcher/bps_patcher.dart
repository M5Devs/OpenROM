// SPDX-License-Identifier: GPL-3.0-or-later
// Ported from Final ROM (https://github.com/eon-com/final_rom) and
// UniPatcher (https://github.com/btimofeev/UniPatcher) — both GPL v3.
// Adapted for OpenROM by M5 Dev.
import 'dart:typed_data';
import 'patcher.dart';
import 'checksums.dart';

/// BPS (Binary Patch System) patcher. Ported from UniPatcher's `BPS.kt`.
///
/// BPS records are tiny and numerous (with many overlapping back-references),
/// so the ROM, patch and output are all held in memory and rebuilt with tight
/// in-memory loops; per-record async file I/O is far too slow. BPS targets
/// console ROMs (NES/SNES/GBA), so this is safe. The three embedded CRC32
/// values (source, target, patch) are verified unless [apply] is called with
/// `ignoreChecksum: true`.
class BpsPatcher extends RomPatcher {
  BpsPatcher({
    required super.patchFile,
    required super.romFile,
    required super.outputFile,
  });

  static const int _allChecksumsSize = 12;

  @override
  Future<PatchReport> apply({bool ignoreChecksum = false}) async {
    final patchBytes = await patchFile.readAsBytes();
    if (patchBytes.length < 19) {
      throw PatchException("Patch file is too small or corrupted.");
    }
    if (patchBytes[0] != 0x42 ||
        patchBytes[1] != 0x50 ||
        patchBytes[2] != 0x53 ||
        patchBytes[3] != 0x31) {
      // "BPS1"
      throw PatchException("Not a valid BPS patch.");
    }

    // The last 12 bytes are: source CRC, target CRC, patch CRC (each LE32).
    final int sourceCrc = _readUint32LE(patchBytes, patchBytes.length - 12);
    final int targetCrc = _readUint32LE(patchBytes, patchBytes.length - 8);
    final int patchCrc = _readUint32LE(patchBytes, patchBytes.length - 4);

    final rom = await romFile.readAsBytes();

    if (!ignoreChecksum) {
      final actualPatchCrc = crc32Bytes(patchBytes, 0, patchBytes.length - 4);
      if (actualPatchCrc != patchCrc) {
        throw PatchException("Patch file is corrupted (CRC mismatch).");
      }
      final actualSourceCrc = crc32Bytes(rom);
      if (actualSourceCrc != sourceCrc) {
        throw PatchException("ROM is not compatible with this patch.");
      }
    }

    int patchOffset = 4; // skip magic

    int decode() {
      int offset = 0;
      int shift = 1;
      while (true) {
        final x = patchBytes[patchOffset++];
        offset += (x & 0x7f) * shift;
        if ((x & 0x80) != 0) break;
        shift <<= 7;
        offset += shift;
      }
      return offset;
    }

    decode(); // source size (we read the ROM directly, so not needed)
    final targetSize = decode();
    final metadataSize = decode();
    patchOffset += metadataSize;

    final out = Uint8List(targetSize);
    int outputPos = 0;
    int romRelOffset = 0;
    int outRelOffset = 0;

    while (patchOffset < patchBytes.length - _allChecksumsSize) {
      int length = decode();
      final mode = length & 3;
      length = (length >> 2) + 1;

      switch (mode) {
        case 0: // SOURCE_READ — copy from ROM at the current output position
          out.setRange(outputPos, outputPos + length, rom, outputPos);
          outputPos += length;
          break;
        case 1: // TARGET_READ — copy literal bytes from the patch
          out.setRange(outputPos, outputPos + length, patchBytes, patchOffset);
          patchOffset += length;
          outputPos += length;
          break;
        case 2: // SOURCE_COPY — copy from ROM at a relative offset
          int offset = decode();
          offset = ((offset & 1) != 0 ? -1 : 1) * (offset >> 1);
          romRelOffset += offset;
          out.setRange(outputPos, outputPos + length, rom, romRelOffset);
          romRelOffset += length;
          outputPos += length;
          break;
        case 3: // TARGET_COPY — copy from already-written output (may overlap)
          int offset = decode();
          offset = ((offset & 1) != 0 ? -1 : 1) * (offset >> 1);
          outRelOffset += offset;
          for (int k = 0; k < length; k++) {
            out[outputPos++] = out[outRelOffset++];
          }
          break;
      }
    }

    await outputFile.writeAsBytes(out);

    if (!ignoreChecksum) {
      final actualTargetCrc = crc32Bytes(out);
      if (actualTargetCrc != targetCrc) {
        throw PatchException("Wrong checksum after patching.");
      }
    }

    final outcome =
        ignoreChecksum ? CheckOutcome.skipped : CheckOutcome.passed;
    return PatchReport(format: "BPS", checks: [
      PatchCheck("Patch (CRC32)", outcome),
      PatchCheck("Source ROM (CRC32)", outcome),
      PatchCheck("Output (CRC32)", outcome),
    ]);
  }

  int _readUint32LE(Uint8List bytes, int offset) {
    return bytes[offset] |
        (bytes[offset + 1] << 8) |
        (bytes[offset + 2] << 16) |
        (bytes[offset + 3] << 24);
  }
}
