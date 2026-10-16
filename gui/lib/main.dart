// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openrom_core/openrom_core.dart' as core;
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'providers/locale_provider.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    try {
      const channel = MethodChannel('com.m5dev.openrom/native');
      final String? libDir =
          await channel.invokeMethod<String>('getNativeLibraryDir');
      if (libDir != null && libDir.isNotEmpty) {
        await core.initAndroid(libDir);
      }
    } catch (e) {
      debugPrint('Failed to initialize Android native library dir: $e');
    }
  } else {
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
  }

  final themeService = ThemeService();
  final localeProvider = LocaleProvider();
  runApp(
    OpenROMApp(themeService: themeService, localeProvider: localeProvider),
  );
}
