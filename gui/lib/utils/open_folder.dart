// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:io';

/// Reveals [path] in the platform's file manager. Best-effort: a failure to
/// launch the explorer is swallowed so it never interrupts the UI.
Future<bool> openFolderInFileManager(String path) async {
  if (path.isEmpty || !Directory(path).existsSync()) return false;
  try {
    if (Platform.isWindows) {
      await Process.run('explorer', [path]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [path]);
    } else {
      await Process.run('xdg-open', [path]);
    }
    return true;
  } catch (_) {
    return false;
  }
}
