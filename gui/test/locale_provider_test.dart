import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gui/providers/locale_provider.dart';

void main() {
  group('LocaleProvider.getNativeName', () {
    test('distinguishes Simplified and Traditional Chinese', () {
      expect(
        LocaleProvider.getNativeName(const Locale('zh')),
        '简体中文',
      );
      expect(
        LocaleProvider.getNativeName(const Locale('zh', 'TW')),
        '繁體中文',
      );
    });

    test('falls back to the language name for other locales', () {
      expect(LocaleProvider.getNativeName(const Locale('ja')), '日本語');
      expect(LocaleProvider.getNativeName(const Locale('en')), 'English');
    });
  });
}
