// SPDX-License-Identifier: GPL-3.0-or-later
// Ported from Final ROM (https://github.com/eon-com/final_rom) and
// UniPatcher (https://github.com/btimofeev/UniPatcher) — both GPL v3.
// Adapted for OpenROM by M5 Dev.
import 'dart:io';
import 'patcher.dart';
import 'aps_gba_patcher.dart';
import 'aps_n64_patcher.dart';

/// APS dispatcher. Ported from UniPatcher's `APS.kt`. Selects the GBA or N64
/// implementation by magic number: "APS10" (N64) or "APS1" (GBA). The N64
/// magic is a superset of the GBA one, so it is tested first.
class ApsPatcher extends RomPatcher {
  ApsPatcher({
    required super.patchFile,
    required super.romFile,
    required super.outputFile,
  });

  static const List<int> _n64Magic = [0x41, 0x50, 0x53, 0x31, 0x30]; // "APS10"
  static const List<int> _gbaMagic = [0x41, 0x50, 0x53, 0x31]; // "APS1"

  @override
  Future<PatchReport> apply({bool ignoreChecksum = false}) async {
    final RomPatcher delegate = switch (await _detectType()) {
      _ApsType.n64 => ApsN64Patcher(
          patchFile: patchFile, romFile: romFile, outputFile: outputFile),
      _ApsType.gba => ApsGbaPatcher(
          patchFile: patchFile, romFile: romFile, outputFile: outputFile),
      _ApsType.unknown => throw PatchException("Not a valid APS patch."),
    };
    return delegate.apply(ignoreChecksum: ignoreChecksum);
  }

  Future<_ApsType> _detectType() async {
    final raf = await patchFile.open(mode: FileMode.read);
    try {
      final header = await raf.read(5);
      if (header.length >= 5 && _startsWith(header, _n64Magic)) {
        return _ApsType.n64;
      }
      if (header.length >= 4 && _startsWith(header, _gbaMagic)) {
        return _ApsType.gba;
      }
      return _ApsType.unknown;
    } finally {
      await raf.close();
    }
  }

  bool _startsWith(List<int> data, List<int> prefix) {
    if (data.length < prefix.length) return false;
    for (int i = 0; i < prefix.length; i++) {
      if (data[i] != prefix[i]) return false;
    }
    return true;
  }
}

enum _ApsType { n64, gba, unknown }
