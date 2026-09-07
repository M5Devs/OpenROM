// SPDX-License-Identifier: GPL-3.0-or-later
// Ported from Final ROM (https://github.com/eon-com/final_rom) and
// UniPatcher (https://github.com/btimofeev/UniPatcher) — both GPL v3.
// Adapted for OpenROM by M5 Dev.
import 'dart:io';
import '../core/config.dart';
import 'patcher.dart';

/// xdelta3 / VCDIFF patcher — delegates to the xdelta3 binary via subprocess.
/// OpenROM ships xdelta3 as a bundled tool (same pattern as chdman/maxcso).
/// Ported from UniPatcher (GPL v3) / Final ROM (GPL v3).
class XdeltaPatcher extends RomPatcher {
  XdeltaPatcher({
    required super.patchFile,
    required super.romFile,
    required super.outputFile,
  });

  static const List<String> _xdelta1Magics = [
    '%XDELTA%', '%XDZ000%', '%XDZ001%',
    '%XDZ002%', '%XDZ003%', '%XDZ004%',
  ];

  @override
  Future<PatchReport> apply({bool ignoreChecksum = false}) async {
    if (await _isXdelta1()) {
      throw PatchException('XDelta1 patches are not supported.');
    }

    // Resolve xdelta3 binary next to the executable (same as chdman)
    final binary = AppConfig.xdelta3Path;

    if (!await File(binary).exists()) {
      throw PatchException(
          'xdelta3 binary not found. Please re-download the full ZIP.');
    }

    final args = [
      '-d',                          // decode (apply patch)
      if (ignoreChecksum) '-n',      // no checksum verification
      '-s', romFile.path,
      patchFile.path,
      outputFile.path,
    ];

    final result = await Process.run(binary, args);

    if (result.exitCode != 0) {
      final err = (result.stderr as String).trim();
      if (err.contains('source size')) {
        throw PatchException('ROM is not compatible with this patch.');
      }
      throw PatchException('xdelta3 failed: $err');
    }

    return PatchReport(format: 'xdelta', checks: [
      PatchCheck('VCDIFF integrity',
          ignoreChecksum ? CheckOutcome.skipped : CheckOutcome.passed),
    ]);
  }

  Future<bool> _isXdelta1() async {
    final raf = await patchFile.open(mode: FileMode.read);
    try {
      final magic = await raf.read(8);
      if (magic.length < 8) return false;
      return _xdelta1Magics.contains(String.fromCharCodes(magic));
    } finally {
      await raf.close();
    }
  }
}
