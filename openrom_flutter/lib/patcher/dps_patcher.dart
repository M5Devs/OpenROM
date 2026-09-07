// SPDX-License-Identifier: GPL-3.0-or-later
// Ported from Final ROM (https://github.com/eon-com/final_rom) and
// UniPatcher (https://github.com/btimofeev/UniPatcher) — both GPL v3.
// Adapted for OpenROM by M5 Dev.
import 'dart:io';
import 'dart:typed_data';
import 'patcher.dart';
import 'patch_io.dart';

/// DPS (Dreamcast/Direct Patch Stream) patcher. Ported from UniPatcher's
/// `DPS.java`.
///
/// The output is built from scratch by a stream of records that either copy a
/// run of bytes from the source ROM (COPY_DATA) or write literal bytes embedded
/// in the patch (ENCLOSED_DATA), each at an absolute output offset.
class DpsPatcher extends RomPatcher {
  DpsPatcher({
    required super.patchFile,
    required super.romFile,
    required super.outputFile,
  });

  static const int _minSizePatch = 136;
  static const int _copyData = 0;
  static const int _enclosedData = 1;

  @override
  Future<PatchReport> apply({bool ignoreChecksum = false}) async {
    final patchLen = await patchFile.length();
    if (patchLen < _minSizePatch) {
      throw PatchException("Patch file is too small or corrupted.");
    }

    RandomAccessFile? patch;
    RandomAccessFile? rom;
    RandomAccessFile? output;

    try {
      patch = await patchFile.open(mode: FileMode.read);

      // Read the 198-byte header into a fixed, zero-padded buffer.
      final header = Uint8List(198);
      final headerRead = await patch.read(198);
      header.setRange(0, headerRead.length, headerRead);

      if (header[193] != 1) {
        throw PatchException("Not a valid DPS patch.");
      }

      if (!ignoreChecksum) {
        final romSize = _getUint(header, 194);
        if (romSize != await romFile.length()) {
          throw PatchException("ROM is not compatible with this patch.");
        }
      }

      rom = await romFile.open(mode: FileMode.read);
      output = await outputFile.open(mode: FileMode.write);

      while (true) {
        final record = await patch.read(5);
        if (record.length < 5) break;

        final mode = record[0];
        final offset = _getUint(record, 1);
        await output.setPosition(offset);

        switch (mode) {
          case _copyData:
            final params = await _readFull(patch, 8);
            final srcOffset = _getUint(params, 0);
            final length = _getUint(params, 4);
            await rom.setPosition(srcOffset);
            await copyBytes(rom, output, length);
            break;
          case _enclosedData:
            final params = await _readFull(patch, 4);
            final length = _getUint(params, 0);
            await copyBytes(patch, output, length);
            break;
        }
      }
    } finally {
      await patch?.close();
      await rom?.close();
      await output?.close();
    }

    return PatchReport(format: "DPS", checks: [
      PatchCheck("ROM size",
          ignoreChecksum ? CheckOutcome.skipped : CheckOutcome.passed),
    ]);
  }

  int _getUint(List<int> bytes, int offset) {
    return (bytes[offset] & 0xff) +
        ((bytes[offset + 1] & 0xff) << 8) +
        ((bytes[offset + 2] & 0xff) << 16) +
        ((bytes[offset + 3] & 0xff) << 24);
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
    return out;
  }
}
