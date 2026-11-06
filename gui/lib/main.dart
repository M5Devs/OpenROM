// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'controllers/plugin_builder_controller.dart';
import 'providers/locale_provider.dart';
import 'services/deeplink_service.dart';
import 'services/skin_manager.dart';
import 'services/theme_service.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // `openrom://` links arrive either as a process argument (cold start) or via
  // the native host after launch (warm start). The service unifies both.
  final deepLinkService = DeepLinkService();

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

  // Resolve the app config dir once so SkinManager can read/write
  // <configDir>/themes without an async hop on every call. A failure here must
  // not block startup — skins simply stay unavailable until a restart.
  try {
    await SkinManager.init();
  } catch (e) {
    debugPrint('SkinManager init failed: $e');
  }

  final themeService = ThemeService();
  final localeProvider = LocaleProvider();
  final builderController = PluginBuilderController();
  await deepLinkService.start(launchArgs: args);

  runApp(
    OpenROMApp(
      themeService: themeService,
      localeProvider: localeProvider,
      builderController: builderController,
      deepLinkService: deepLinkService,
    ),
  );
}
