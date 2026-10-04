// OpenROM — Runtime version reader
// M5 Dev | GPL v3

import 'dart:io';
import 'package:path/path.dart' as p;

/// Reads the VERSION file bundled next to the executable.
/// Falls back to 'unknown' if not found.
String readAppVersion() {
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
