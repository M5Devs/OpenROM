// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _prefKey = 'locale';

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ar'),
    Locale('es'),
    Locale('fr'),
    Locale('ja'),
    Locale('pt'),
    Locale('zh'),
    Locale('zh', 'TW'),
  ];

  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  String get _localeCode {
    if (_locale.countryCode != null && _locale.countryCode!.isNotEmpty) {
      return '${_locale.languageCode}_${_locale.countryCode}';
    }
    return _locale.languageCode;
  }

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefKey);
    if (code != null && code.isNotEmpty) {
      if (supportedLocales.any((l) => l.languageCode == code)) {
        _locale = Locale(code);
        notifyListeners();
      } else if (code.contains('_')) {
        final parts = code.split('_');
        if (parts.length == 2) {
          final locale = Locale(parts[0], parts[1]);
          if (supportedLocales.any((l) =>
              l.languageCode == locale.languageCode &&
              l.countryCode == locale.countryCode)) {
            _locale = locale;
            notifyListeners();
          }
        }
      }
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    if (!supportedLocales.any(
      (l) => l.languageCode == newLocale.languageCode,
    )) {
      return;
    }
    if (_locale == newLocale) return;
    _locale = newLocale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, _localeCode);
  }

  static String getNativeName(String code) {
    switch (code) {
      case 'ar':
        return 'العربية';
      case 'es':
        return 'Español';
      case 'fr':
        return 'Français';
      case 'ja':
        return '日本語';
      case 'pt':
        return 'Português';
      case 'zh':
        return '简体中文';
      case 'zh_TW':
        return '繁體中文';
      case 'en':
      default:
        return 'English';
    }
  }
}