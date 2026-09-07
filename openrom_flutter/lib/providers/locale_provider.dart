// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3 + Commons Clause

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
  ];

  Locale _locale = const Locale('en');

  Locale get locale => _locale;

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
      }
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    if (!supportedLocales.any((l) => l.languageCode == newLocale.languageCode)) {
      return;
    }
    if (_locale == newLocale) return;
    _locale = newLocale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, newLocale.languageCode);
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
      case 'en':
      default:
        return 'English';
    }
  }
}
