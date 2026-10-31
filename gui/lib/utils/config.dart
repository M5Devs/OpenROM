// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'package:openrom_core/openrom_core.dart' as core;

class AppConfig {
  /// Resolves a bundled tool binary using the core's standard resolution logic:
  /// config.json override -> bundled `assets/<os>[/<arch>]/<tool>` -> OS PATH.
  /// This finds tools shipped in the release `assets/` folder (e.g.
  /// `assets/windows/x86_64/xdelta3.exe`, `assets/windows/xdelta3.exe`) rather
  /// than only looking next to the main executable.
  static String getToolPath(String toolName) => core.getToolPath(toolName);

  static String get xdelta3Path => getToolPath('xdelta3');
}
