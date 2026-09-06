// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3 + Commons Clause

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/theme_config.dart';

class ThemeService extends ChangeNotifier {
  ThemeConfig _currentTheme = ThemeConfig.defaultTheme();
  List<ThemeConfig> _availableThemes = [];

  ThemeConfig get currentTheme => _currentTheme;
  List<ThemeConfig> get availableThemes => _availableThemes;

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
  }

  Future<void> loadThemes() async {
    final List<String> themeFiles = [
      'themes/default.json',
      'themes/cyberpunk.json',
      'themes/terminal.json',
      'themes/minimal.json',
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

    if (_availableThemes.isNotEmpty && _currentTheme.name == 'Gaming Dashboard') {
      _currentTheme = _availableThemes.first;
    }
    notifyListeners();
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
