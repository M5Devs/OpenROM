// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3 + Commons Clause

import 'dart:io';

class AppConfig {
  /// Resolves tool binary path relative to executable.
  /// Windows: <tool>.exe, Linux/macOS: <tool>
  static String getToolPath(String toolName) {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final binaryName = Platform.isWindows ? '$toolName.exe' : toolName;
    return '$exeDir${Platform.pathSeparator}$binaryName';
  }

  static String get xdelta3Path => getToolPath('xdelta3');
}
