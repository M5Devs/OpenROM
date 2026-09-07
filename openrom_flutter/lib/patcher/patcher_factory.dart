// SPDX-License-Identifier: GPL-3.0-or-later
// Ported from Final ROM (https://github.com/eon-com/final_rom) and
// UniPatcher (https://github.com/btimofeev/UniPatcher) — both GPL v3.
// Adapted for OpenROM by M5 Dev.
import 'dart:io';
import 'package:path/path.dart' as p;

import 'patcher.dart';
import 'ips_patcher.dart';
import 'ups_patcher.dart';
import 'bps_patcher.dart';
import 'ppf_patcher.dart';
import 'aps_patcher.dart';
import 'ebp_patcher.dart';
import 'dps_patcher.dart';
import 'xdelta_patcher.dart';

/// Selects and constructs the right [RomPatcher] for a patch file, based on its
/// extension. Ported from UniPatcher's `PatcherFactory.kt`.
class PatcherFactory {
  /// All patch-file extensions the app recognises (without the leading dot).
  /// Shared by the file picker and the drag-and-drop handler so they stay in
  /// sync with what the factory can actually dispatch.
  static const Set<String> supportedExtensions = {
    'ips',
    'ips32',
    'ups',
    'bps',
    'ppf',
    'aps',
    'ebp',
    'dps',
    'xdelta',
    'xdelta3',
    'xd',
    'vcdiff',
  };

  /// Returns true if [path] has a recognised patch extension.
  static bool isSupportedPatch(String path) {
    final ext = p.extension(path).toLowerCase().replaceFirst('.', '');
    return supportedExtensions.contains(ext);
  }

  /// Returns a short, human-readable format label for [path] based on its
  /// extension (e.g. "BPS", "IPS32", "xdelta"), or null if the extension is not
  /// a recognised patch format. Lets the UI show a detected-format badge
  /// without instantiating or running a patcher.
  static String? formatName(String path) {
    final ext = p.extension(path).toLowerCase().replaceFirst('.', '');
    switch (ext) {
      case 'ips':
        return 'IPS';
      case 'ips32':
        return 'IPS32';
      case 'ups':
        return 'UPS';
      case 'bps':
        return 'BPS';
      case 'ppf':
        return 'PPF';
      case 'aps':
        return 'APS';
      case 'ebp':
        return 'EBP';
      case 'dps':
        return 'DPS';
      case 'xdelta':
      case 'xdelta3':
      case 'xd':
      case 'vcdiff':
        return 'xdelta';
      default:
        return null;
    }
  }

  /// Creates a patcher for [patchFile], applying it to [romFile] and writing to
  /// [outputFile]. Throws [PatchException] for unknown extensions.
  static RomPatcher create({
    required File patchFile,
    required File romFile,
    required File outputFile,
  }) {
    final ext = p.extension(patchFile.path).toLowerCase().replaceFirst('.', '');
    switch (ext) {
      case 'ips':
      case 'ips32':
        return IpsPatcher(
            patchFile: patchFile, romFile: romFile, outputFile: outputFile);
      case 'ups':
        return UpsPatcher(
            patchFile: patchFile, romFile: romFile, outputFile: outputFile);
      case 'bps':
        return BpsPatcher(
            patchFile: patchFile, romFile: romFile, outputFile: outputFile);
      case 'ppf':
        return PpfPatcher(
            patchFile: patchFile, romFile: romFile, outputFile: outputFile);
      case 'aps':
        return ApsPatcher(
            patchFile: patchFile, romFile: romFile, outputFile: outputFile);
      case 'ebp':
        return EbpPatcher(
            patchFile: patchFile, romFile: romFile, outputFile: outputFile);
      case 'dps':
        return DpsPatcher(
            patchFile: patchFile, romFile: romFile, outputFile: outputFile);
      case 'xdelta':
      case 'xdelta3':
      case 'xd':
      case 'vcdiff':
        return XdeltaPatcher(
            patchFile: patchFile, romFile: romFile, outputFile: outputFile);
      default:
        throw PatchException("Unknown patch format: .$ext");
    }
  }
}
