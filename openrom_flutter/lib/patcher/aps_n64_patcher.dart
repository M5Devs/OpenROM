// SPDX-License-Identifier: GPL-3.0-or-later
// Ported from Final ROM (https://github.com/eon-com/final_rom) and
// UniPatcher (https://github.com/btimofeev/UniPatcher) — both GPL v3.
// Adapted for OpenROM by M5 Dev.
import 'dart:io';
import 'dart:typed_data';
import 'patcher.dart';
import 'patch_io.dart';

/// APS patcher for the N64 variant (magic "APS10"). Ported from UniPatcher's
/// `APS_N64.java`.
///
/// This is a streaming, IPS-like format: records carry an absolute offset plus
/// either literal or run-length-encoded data. N64-type patches additionally
/// embed header fields used to validate the source ROM.
class ApsN64Patcher extends RomPatcher {
  ApsN64Patcher({
    required super.patchFile,
    required super.romFile,
    required super.outputFile,
  });

  static const List<int> _magic = [0x41, 0x50, 0x53, 0x31, 0x30]; // "APS10"
  static const int _typeSimplePatch = 0;
  static const int _typeN64Patch = 1;
  static const int _encodingSimple = 0;

  @override
  Future<PatchReport> apply({bool ignoreChecksum = false}) async {
    final patchSize = await patchFile.length();
    final romSize = await romFile.length();

    RandomAccessFile? patch;
    RandomAccessFile? rom;
    RandomAccessFile? output;
    bool validatesRomHeader = false;

    try {
      patch = await patchFile.open(mode: FileMode.read);

      int romPos = 0;
      int outPos = 0;
      int patchPos = 0;

      final magic = await patch.read(5);
      if (magic.length != 5 || !_bytesEqual(magic, _magic)) {
        throw PatchException("Not a valid APS patch.");
      }
      patchPos += 5;

      final patchType = await patch.readByte();
      if (patchType != _typeSimplePatch && patchType != _typeN64Patch) {
        throw PatchException("Not a valid APS patch.");
      }
      patchPos += 1;

      final encoding = await patch.readByte();
      if (encoding != _encodingSimple) {
        throw PatchException("Not a valid APS patch.");
      }
      patchPos += 1;

      await patch.read(50); // skip description
      patchPos += 50;

      if (patchType == _typeN64Patch) {
        validatesRomHeader = true;
        final endianness = await patch.readByte();
        final cardId =
            ((await patch.readByte() & 0xff) << 8) + (await patch.readByte() & 0xff);
        final country = await patch.readByte();
        final crc = await patch.read(8);
        if (!ignoreChecksum) {
          if (!await _validateRom(endianness, cardId, country, crc)) {
            throw PatchException("ROM is not compatible with this patch.");
          }
        }
        await patch.read(5); // skip bytes reserved for future expansion
        patchPos += 17;
      }

      final outSize = await _readLEUint32(patch);
      patchPos += 4;

      rom = await romFile.open(mode: FileMode.read);
      output = await outputFile.open(mode: FileMode.write);

      while (patchPos < patchSize) {
        final offset = await _readLEUint32(patch);
        patchPos += 4;

        // Copy unchanged ROM data up to the record offset.
        if (offset <= romSize) {
          if (outPos < offset) {
            final size = offset - outPos;
            await copyBytes(rom, output, size);
            romPos += size;
            outPos += size;
          }
        } else {
          if (outPos < romSize) {
            final size = romSize - outPos;
            await copyBytes(rom, output, size);
            romPos += size;
            outPos += size;
          }
          if (outPos < offset) {
            final size = offset - outPos;
            await fillBytes(output, size, 0);
            outPos += size;
          }
        }

        // Copy the record payload (literal or RLE) from the patch.
        int size = await patch.readByte();
        patchPos += 1;
        if (size != 0) {
          final data = await patch.read(size);
          patchPos += size;
          await output.writeFrom(data);
          outPos += size;
        } else {
          final value = await patch.readByte();
          size = await patch.readByte();
          patchPos += 2;
          await fillBytes(output, size, value);
          outPos += size;
        }

        // Skip the corresponding ROM bytes that the record replaced.
        if (offset <= romSize) {
          if (romPos + size > romSize) {
            romPos = romSize;
          } else {
            await rom.setPosition(romPos + size);
            romPos += size;
          }
        }
      }

      // Write the ROM tail and trim to the recorded output size.
      await copyBytes(rom, output, outSize - outPos);
    } finally {
      await patch?.close();
      await rom?.close();
      await output?.close();
    }

    // Only N64-type patches embed ROM-header validation fields; the simple
    // variant carries nothing to verify.
    return PatchReport(
      format: "APS",
      checks: validatesRomHeader
          ? [
              PatchCheck("ROM header",
                  ignoreChecksum ? CheckOutcome.skipped : CheckOutcome.passed),
            ]
          : const [],
    );
  }

  Future<bool> _validateRom(
      int endianness, int cartId, int country, List<int> crc) async {
    final rom = await romFile.open(mode: FileMode.read);
    try {
      // Check endianness marker.
      int val = await rom.readByte();
      if ((endianness == 1 && val != 0x80) || (endianness == 0 && val != 0x37)) {
        return false;
      }

      // Check cartridge ID.
      await rom.setPosition(0x3c);
      if (endianness == 1) {
        val = ((await rom.readByte() & 0xff) << 8) + (await rom.readByte() & 0xff);
      } else {
        val = (await rom.readByte() & 0xff) + ((await rom.readByte() & 0xff) << 8);
      }
      if (cartId != val) return false;

      // Check country.
      val = await rom.readByte();
      if (endianness == 0) {
        val = await rom.readByte();
      }
      if (country != val) return false;

      // Check CRC bytes.
      await rom.setPosition(0x10);
      final buf = await rom.read(8);
      final cmp = Uint8List.fromList(buf);
      if (endianness == 0) {
        for (int i = 0; i < cmp.length; i += 2) {
          final tmp = cmp[i];
          cmp[i] = cmp[i + 1];
          cmp[i + 1] = tmp;
        }
      }
      if (!_bytesEqual(crc, cmp)) return false;
    } finally {
      await rom.close();
    }
    return true;
  }

  Future<int> _readLEUint32(RandomAccessFile raf) async {
    final b = await raf.read(4);
    return (b[0] & 0xff) +
        ((b[1] & 0xff) << 8) +
        ((b[2] & 0xff) << 16) +
        ((b[3] & 0xff) << 24);
  }

  bool _bytesEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
