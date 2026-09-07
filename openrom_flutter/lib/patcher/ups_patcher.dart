// SPDX-License-Identifier: GPL-3.0-or-later
// Ported from Final ROM (https://github.com/eon-com/final_rom) and
// UniPatcher (https://github.com/btimofeev/UniPatcher) — both GPL v3.
// Adapted for OpenROM by M5 Dev.
import 'dart:typed_data';
import 'patcher.dart';
import 'checksums.dart';

/// UPS (Universal Patch System) patcher. Ported from UniPatcher's `UPS.java`.
///
/// UPS is an XOR-delta format with variable-length integer offsets. The patch,
/// the ROM and the output are all held in memory and the XOR is applied with
/// tight in-memory loops: UPS patches can rewrite very large spans of a ROM
/// (e.g. full fan-translations), so per-byte async file I/O is far too slow.
/// UPS targets console ROMs (NES/SNES/GBA, up to ~32 MB), so this is safe.
///
/// The format is bidirectional: if the supplied ROM matches the recorded
/// *output* CRC instead of the *input* CRC, the patch is applied in reverse.
class UpsPatcher extends RomPatcher {
  UpsPatcher({
    required super.patchFile,
    required super.romFile,
    required super.outputFile,
  });

  @override
  Future<PatchReport> apply({bool ignoreChecksum = false}) async {
    final patchBytes = await patchFile.readAsBytes();
    if (patchBytes.length < 18) {
      throw PatchException("Patch file is too small or corrupted.");
    }
    if (patchBytes[0] != 0x55 ||
        patchBytes[1] != 0x50 ||
        patchBytes[2] != 0x53 ||
        patchBytes[3] != 0x31) {
      // "UPS1"
      throw PatchException("Not a valid UPS patch.");
    }

    final length = patchBytes.length;
    // Footer: input CRC, output CRC, patch CRC (each LE32) in the last 12 bytes.
    int inputCrc = _readUint32LE(patchBytes, length - 12);
    int outputCrc = _readUint32LE(patchBytes, length - 8);
    final patchCrc = _readUint32LE(patchBytes, length - 4);

    if (!ignoreChecksum) {
      final realPatchCrc = crc32Bytes(patchBytes, 0, length - 4);
      if (realPatchCrc != patchCrc) {
        throw PatchException("Patch file is corrupted (CRC mismatch).");
      }
    }

    int patchPos = 4; // skip magic

    int decode() {
      int offset = 0;
      int shift = 1;
      while (true) {
        final x = patchBytes[patchPos++];
        offset += (x & 0x7f) * shift;
        if ((x & 0x80) != 0) break;
        shift <<= 7;
        offset += shift;
      }
      return offset;
    }

    int xSize = decode(); // source size
    int ySize = decode(); // output size

    final rom = await romFile.readAsBytes();
    final romLen = rom.length;
    final realRomCrc = crc32Bytes(rom);

    if (romLen == xSize && realRomCrc == inputCrc) {
      // Forward patch — sizes/CRCs already correct.
    } else if (romLen == ySize && realRomCrc == outputCrc) {
      // Reverse patch — swap sizes and CRCs.
      final tmpSize = xSize;
      xSize = ySize;
      ySize = tmpSize;
      final tmpCrc = inputCrc;
      inputCrc = outputCrc;
      outputCrc = tmpCrc;
    } else {
      if (!ignoreChecksum) {
        throw PatchException("ROM is not compatible with this patch.");
      }
    }

    final out = Uint8List(ySize);
    int outPos = 0;
    int romCursor = 0; // sequential read position in the ROM
    int offset = 0;

    while (patchPos < length - 12) {
      offset += decode();
      if (offset > ySize) {
        continue;
      }
      // Copy unchanged ROM data up to the next difference.
      final copyLen = offset - outPos;
      if (copyLen > 0) {
        final available = romLen - romCursor;
        final n = copyLen <= available ? copyLen : (available > 0 ? available : 0);
        if (n > 0) {
          out.setRange(outPos, outPos + n, rom, romCursor);
          romCursor += n;
        }
        outPos = offset;
      }

      // XOR the patch bytes over the ROM until the 0x00 terminator.
      for (int i = offset; i < ySize; i++) {
        final x = patchBytes[patchPos++];
        offset++;
        if (x == 0x00) {
          break;
        }
        int y = 0;
        if (i < xSize) {
          y = romCursor < romLen ? rom[romCursor] : 0;
          romCursor++;
        }
        out[outPos] = (x ^ y) & 0xFF;
        outPos++;
      }
    }

    // Write the ROM tail and trim to the output size.
    final tail = ySize - outPos;
    if (tail > 0) {
      final available = romLen - romCursor;
      final n = tail <= available ? tail : (available > 0 ? available : 0);
      if (n > 0) {
        out.setRange(outPos, outPos + n, rom, romCursor);
      }
    }

    await outputFile.writeAsBytes(out);

    if (!ignoreChecksum) {
      final realOutCrc = crc32Bytes(out);
      if (realOutCrc != outputCrc) {
        throw PatchException("Wrong checksum after patching.");
      }
    }

    final outcome =
        ignoreChecksum ? CheckOutcome.skipped : CheckOutcome.passed;
    return PatchReport(format: "UPS", checks: [
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
