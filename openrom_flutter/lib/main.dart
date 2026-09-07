// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3 + Commons Clause

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'app.dart';
import 'providers/locale_provider.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      size: Size(1100, 720),
      minimumSize: Size(800, 500),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      title: 'OpenROM — Universal ROM Compression Suite',
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  } catch (_) {
    // Window manager setup fallback if headlessly executing or uninitialized
  }

  final themeService = ThemeService();
  final localeProvider = LocaleProvider();
  runApp(OpenROMApp(themeService: themeService, localeProvider: localeProvider));
}
