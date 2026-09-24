import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gui/models/theme_config.dart';

void main() {
  group('ThemeConfig Tests', () {
    test('defaultTheme and copyWith', () {
      final theme = ThemeConfig.defaultTheme();
      expect(theme.name, 'Gaming Dashboard');

      final updated = theme.copyWith(name: 'New Custom Theme', accent: const Color(0xff00ff00));
      expect(updated.name, 'New Custom Theme');
      expect(updated.accent, const Color(0xff00ff00));
      expect(updated.background, theme.background);
    });

    test('toJson and fromJson serialization roundtrip', () {
      final theme = ThemeConfig.defaultTheme();
      final json = theme.toJson();

      expect(json['name'], 'Gaming Dashboard');
      expect(json['accent'], '#e94560');

      final reconstructed = ThemeConfig.fromJson(json);
      expect(reconstructed.name, theme.name);
      expect(reconstructed.accent, theme.accent);
      expect(reconstructed.background, theme.background);
      expect(reconstructed.surface, theme.surface);
      expect(reconstructed.textPrimary, theme.textPrimary);
      expect(reconstructed.textSecondary, theme.textSecondary);
      expect(reconstructed.sidebarBg, theme.sidebarBg);
      expect(reconstructed.cardBg, theme.cardBg);
      expect(reconstructed.terminalBg, theme.terminalBg);
      expect(reconstructed.terminalText, theme.terminalText);
      expect(reconstructed.fontFamily, theme.fontFamily);
      expect(reconstructed.borderRadius, theme.borderRadius);
      expect(reconstructed.layout, theme.layout);
    });
  });
}
