// OpenROM — Runtime version reader
// M5 Dev | GPL v3

import 'dart:io';
import 'package:path/path.dart' as p;

/// Reads the app version, in priority order:
/// 1. Compile-time `--dart-define=APP_VERSION=x.y.z`
/// 2. A `VERSION` file next to the executable
/// 3. A `VERSION` file in the current working directory (dev mode)
/// Falls back to 'unknown' if none are found.
String readAppVersion() {
  const definedVersion = String.fromEnvironment('APP_VERSION');
  if (definedVersion.isNotEmpty) {
    return definedVersion;
  }
  try {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final versionFile = File(p.join(exeDir, 'VERSION'));
    if (versionFile.existsSync()) {
      return versionFile.readAsStringSync().trim();
    }
    // Fallback: try relative to CWD (dev mode)
    final devFile = File('VERSION');
    if (devFile.existsSync()) {
      return devFile.readAsStringSync().trim();
    }
  } catch (_) {}
  return 'unknown';
}
