// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:io';

import 'package:openrom_core/openrom_core.dart' as core;

class AppConfig {
  /// Resolves tool binary path relative to executable.
  /// Windows: `<tool>.exe`, Linux/macOS: `<tool>`
  static String getToolPath(String toolName) {
    if (Platform.isAndroid) {
      return core.getToolPath(toolName);
    }
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final binaryName = Platform.isWindows ? '$toolName.exe' : toolName;
    return '$exeDir${Platform.pathSeparator}$binaryName';
  }

  static String get xdelta3Path => getToolPath('xdelta3');
}
