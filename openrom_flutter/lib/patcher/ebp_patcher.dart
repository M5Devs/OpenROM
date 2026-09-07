// SPDX-License-Identifier: GPL-3.0-or-later
// Ported from Final ROM (https://github.com/eon-com/final_rom) and
// UniPatcher (https://github.com/btimofeev/UniPatcher) — both GPL v3.
// Adapted for OpenROM by M5 Dev.
import 'dart:io';
import 'dart:typed_data';
import 'patcher.dart';
import 'ips_patcher.dart';

/// EBP (EarthBound Patch) patcher. Ported from UniPatcher's `EBP.java`.
///
/// An EBP file is, structurally, an IPS patch (it carries the "PATCH" magic and
/// the same record format). UniPatcher additionally performs EarthBound-specific
/// "clean ROM" preparation — stripping the SNES SMC header and repairing known
/// bad dumps via bundled IPS assets keyed by MD5. That repair is specific to a
/// single SNES game and depends on assets we do not ship, so it is intentionally
/// not ported here; we validate the EBP header and apply it as an IPS patch.
class EbpPatcher extends RomPatcher {
  EbpPatcher({
    required super.patchFile,
    required super.romFile,
    required super.outputFile,
  });

  static const List<int> _magic = [0x50, 0x41, 0x54, 0x43, 0x48]; // "PATCH"

  @override
  Future<PatchReport> apply({bool ignoreChecksum = false}) async {
    final patchLen = await patchFile.length();
    if (patchLen < 14) {
      throw PatchException("Patch file is too small or corrupted.");
    }

    final raf = await patchFile.open(mode: FileMode.read);
    Uint8List magic;
    try {
      magic = await raf.read(5);
    } finally {
      await raf.close();
    }
    if (magic.length != 5 || !_bytesEqual(magic, _magic)) {
      throw PatchException("Not a valid EBP patch.");
    }

    // EBP uses the IPS record format, so apply it with the IPS patcher.
    final ips = IpsPatcher(
      patchFile: patchFile,
      romFile: romFile,
      outputFile: outputFile,
    );
    await ips.apply(ignoreChecksum: ignoreChecksum);

    // EBP, like IPS, carries no embedded checksums.
    return const PatchReport(format: "EBP");
  }

  bool _bytesEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
