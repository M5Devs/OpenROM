// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/theme_config.dart';

class ThemeService extends ChangeNotifier {
  ThemeConfig _currentTheme = ThemeConfig.defaultTheme();
  List<ThemeConfig> _availableThemes = [];
  ThemeMode _themeMode = ThemeMode.system;

  ThemeConfig get currentTheme => _currentTheme;
  List<ThemeConfig> get availableThemes => _availableThemes;

  /// The user's light/dark preference. Defaults to [ThemeMode.system] so the
  /// app follows the OS setting when no explicit choice has been stored.
  ThemeMode get themeMode => _themeMode;

  ThemeService() {
    init();
  }

  Future<void> init() async {
    await loadThemes();
    final prefs = await SharedPreferences.getInstance();
    final savedThemeName = prefs.getString('selected_theme');
    if (savedThemeName != null) {
      setThemeByName(savedThemeName);
    }
    final savedMode = prefs.getString('theme_mode');
    if (savedMode != null) {
      _themeMode = _parseThemeMode(savedMode);
    }
    notifyListeners();
  }

  static ThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String themeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', themeModeName(mode));
  }

  /// Resolves the palette to render for the given platform [brightness],
  /// following the system when [themeMode] is [ThemeMode.system].
  ThemeConfig resolvedTheme(Brightness platformBrightness) {
    final wantLight = _themeMode == ThemeMode.light ||
        (_themeMode == ThemeMode.system &&
            platformBrightness == Brightness.light);
    if (wantLight) {
      return _currentTheme.isLight ? _currentTheme : _currentTheme.toLight();
    }
    return _currentTheme.isLight ? _currentTheme.toDark() : _currentTheme;
  }

  Future<void> loadThemes() async {
    final List<String> themeFiles = [
      'themes/default.json',
      'themes/cyberpunk.json',
      'themes/terminal.json',
      'themes/minimal.json',
      'themes/retroarch.json',
    ];

    _availableThemes = [];
    for (final file in themeFiles) {
      try {
        final content = await rootBundle.loadString(file);
        final Map<String, dynamic> jsonMap = jsonDecode(content);
        _availableThemes.add(ThemeConfig.fromJson(jsonMap));
      } catch (e) {
        debugPrint('Failed to load theme $file: $e');
      }
    }

    if (_availableThemes.isEmpty) {
      _availableThemes.add(ThemeConfig.defaultTheme());
    }

    // Load user-saved custom themes from disk
    try {
      final dir = await getApplicationSupportDirectory();
      final customFiles =
          Directory(dir.path).listSync().whereType<File>().where(
                (f) =>
                    f.path.endsWith('.json') &&
                    f.uri.pathSegments.last.startsWith('custom_'),
              );
      for (final file in customFiles) {
        try {
          final content = await file.readAsString();
          final Map<String, dynamic> jsonMap = jsonDecode(content);
          final customTheme = ThemeConfig.fromJson(jsonMap);
          // Don't add duplicates
          if (!_availableThemes.any((t) => t.name == customTheme.name)) {
            _availableThemes.add(customTheme);
          }
        } catch (e) {
          debugPrint('Failed to load custom theme ${file.path}: $e');
        }
      }
    } catch (e) {
      debugPrint('Could not scan custom themes directory: $e');
    }

    if (_availableThemes.isNotEmpty &&
        _currentTheme.name == 'Gaming Dashboard') {
      _currentTheme = _availableThemes.first;
    }
    notifyListeners();
  }

  /// Saves a custom theme as JSON to the app support directory.
  /// File name: `custom_<sanitized_name>.json`
  Future<void> saveCustomTheme(ThemeConfig theme) async {
    try {
      final dir = await getApplicationSupportDirectory();
      final safeName = theme.name.toLowerCase().replaceAll(
            RegExp(r'[^a-z0-9_]'),
            '_',
          );
      final file = File('${dir.path}/custom_$safeName.json');
      await file.writeAsString(jsonEncode(theme.toJson()));

      // Reload themes so the new one appears in availableThemes
      await loadThemes();
    } catch (e) {
      debugPrint('Failed to save custom theme: $e');
    }
  }

  Future<void> setTheme(ThemeConfig theme) async {
    _currentTheme = theme;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_theme', theme.name);
  }

  void setThemeByName(String name) {
    for (final theme in _availableThemes) {
      if (theme.name.toLowerCase() == name.toLowerCase()) {
        setTheme(theme);
        return;
      }
    }
  }
}
