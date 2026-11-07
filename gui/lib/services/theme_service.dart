// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/skin_manifest.dart';
import '../models/theme_config.dart';
import 'skin_manager.dart';

class ThemeService extends ChangeNotifier {
  /// The font family registered by [loadSkinFont] for a skin's bundled font.
  static const String skinFontFamily = 'SkinCustomFont';

  ThemeConfig _currentTheme = ThemeConfig.defaultTheme();
  List<ThemeConfig> _availableThemes = [];
  ThemeMode _themeMode = ThemeMode.system;

  /// Path of the skin font currently registered at runtime, or null.
  String? _loadedSkinFontPath;

  /// Installs/removes `.orskin` bundles. Overridable for tests.
  final SkinManager skinManager;

  ThemeConfig get currentTheme => _currentTheme;
  List<ThemeConfig> get availableThemes => _availableThemes;

  /// Whether a custom skin font is currently loaded and applied.
  bool get hasLoadedSkinFont => _loadedSkinFontPath != null;

  /// The font family the UI should render with: the dynamically-loaded skin
  /// font when one is registered, else the active theme's family.
  String get resolvedFontFamily =>
      _loadedSkinFontPath != null ? skinFontFamily : _currentTheme.fontFamily;

  /// The user's light/dark preference. Defaults to [ThemeMode.system] so the
  /// app follows the OS setting when no explicit choice has been stored.
  ThemeMode get themeMode => _themeMode;

  ThemeService({SkinManager? skinManager})
      : skinManager = skinManager ?? SkinManager() {
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
    // Ensure any font bundled with the active skin is registered at startup.
    await _syncSkinFont(_currentTheme);
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

    // Installed `.orskin` bundles live under <configDir>/themes/<id>/.
    for (final skin in skinManager.listInstalledSkins()) {
      if (!_availableThemes.any((t) => t.name == skin.theme.name)) {
        _availableThemes.add(skin.theme);
      }
    }

    if (_availableThemes.isNotEmpty &&
        _currentTheme.name == 'Gaming Dashboard') {
      _currentTheme = _availableThemes.first;
    }
    notifyListeners();
  }

  /// Imports an `.orskin` bundle, makes its palette available and applies it.
  Future<SkinResult<SkinManifest>> importSkin(File orskin) async {
    final result = await skinManager.importSkin(orskin);
    if (!result.isOk) return result;

    final skin = result.value!;
    final existing = _availableThemes.indexWhere(
      (t) => t.name == skin.theme.name,
    );
    if (existing >= 0) {
      _availableThemes[existing] = skin.theme;
    } else {
      _availableThemes.add(skin.theme);
    }
    await setTheme(skin.theme);
    return result;
  }

  /// Packs the current palette (or [theme]) into an `.orskin` bundle.
  SkinResult<File> exportSkin({
    required ThemeConfig theme,
    required File outputPath,
    File? wallpaper,
    File? dropzone,
    File? font,
    Directory? iconsDir,
    File? preview,
    String? author,
    String? version,
  }) {
    return skinManager.exportSkin(
      theme: theme,
      outputPath: outputPath,
      wallpaper: wallpaper,
      dropzone: dropzone,
      font: font,
      iconsDir: iconsDir,
      preview: preview,
      author: author,
      version: version,
    );
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
    await _syncSkinFont(theme);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_theme', theme.name);
  }

  /// Loads (or clears) the skin's runtime font to match [theme].
  ///
  /// When [ThemeConfig.fontPath] points at an existing `.ttf`/`.otf`, the font
  /// is registered under [skinFontFamily] via a [FontLoader] and applied to the
  /// global [ThemeData.fontFamily] without an app restart. Any failure (missing
  /// file, corrupt font) degrades cleanly to the theme's default family.
  Future<void> _syncSkinFont(ThemeConfig theme) async {
    final path = theme.fontPath;
    if (path == null || path.isEmpty) {
      if (_loadedSkinFontPath != null) {
        _loadedSkinFontPath = null;
      }
      return;
    }
    if (path == _loadedSkinFontPath) return;

    final ok = await loadSkinFont(File(path));
    _loadedSkinFontPath = ok ? path : null;
  }

  /// Registers [fontFile] under [skinFontFamily]. Returns true on success and
  /// false (without throwing) if the font is missing or unreadable.
  Future<bool> loadSkinFont(File fontFile) async {
    try {
      if (!fontFile.existsSync()) return false;
      final bytes = await fontFile.readAsBytes();
      if (bytes.isEmpty) return false;
      final loader = FontLoader(skinFontFamily)
        ..addFont(
          Future.value(ByteData.view(
              bytes.buffer, bytes.offsetInBytes, bytes.lengthInBytes)),
        );
      await loader.load();
      return true;
    } catch (e) {
      debugPrint('Failed to load skin font ${fontFile.path}: $e');
      return false;
    }
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
