// SPDX-License-Identifier: GPL-3.0-or-later
// Ported from Final ROM (https://github.com/eon-com/final_rom) and
// UniPatcher (https://github.com/btimofeev/UniPatcher) — both GPL v3.
// Adapted for OpenROM by M5 Dev.
import 'dart:io';

abstract class RomPatcher {
  final File patchFile;
  final File romFile;
  final File outputFile;

  RomPatcher({
    required this.patchFile,
    required this.romFile,
    required this.outputFile,
  });

  /// Applies the patch and returns a [PatchReport] describing the detected
  /// format and which integrity checks ran. Throws [PatchException] on failure.
  Future<PatchReport> apply({bool ignoreChecksum = false});
}

class PatchException implements Exception {
  final String message;
  PatchException(this.message);

  @override
  String toString() => message;
}

/// Outcome of a single integrity check performed while patching.
enum CheckOutcome {
  /// The check ran and the data matched.
  passed,

  /// The check was bypassed because the user chose to ignore checksums.
  skipped,
}

/// One integrity check a patcher performed (or deliberately skipped).
class PatchCheck {
  /// Human-readable description of what was checked,
  /// e.g. "Source ROM (CRC32)".
  final String label;
  final CheckOutcome outcome;

  const PatchCheck(this.label, this.outcome);
}

/// Summary of a completed patch operation, surfaced to the UI.
///
/// Instances cross the patching isolate boundary, so every field is a plain,
/// copyable value (strings, enums and lists thereof).
class PatchReport {
  /// Short, human-readable format label, e.g. "BPS", "IPS32", "xdelta".
  final String format;

  /// Integrity checks that ran during patching. Empty when the format carries
  /// no embedded checksums to verify.
  final List<PatchCheck> checks;

  const PatchReport({required this.format, this.checks = const []});
}
