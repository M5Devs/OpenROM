// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'package:openrom_core/openrom_core.dart';

class AppVersion {
  /// Default fallback version matching current release tag.
  static const String fallback = '3.9.0';

  /// Returns the resolved app version.
  /// Priority:
  /// 1. Compile-time environment variable (--dart-define=APP_VERSION=x.y.z)
  /// 2. Version file read via `readAppVersion()` from `openrom_core`
  /// 3. Fallback string ('3.9.0')
  static String get current {
    const definedVersion = String.fromEnvironment('APP_VERSION');
    if (definedVersion.isNotEmpty) {
      return definedVersion;
    }

    final readVer = readAppVersion();
    if (readVer.isNotEmpty && readVer != 'unknown') {
      return readVer;
    }

    return fallback;
  }
}
