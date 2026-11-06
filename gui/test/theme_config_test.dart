import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gui/models/theme_config.dart';

void main() {
  group('ThemeConfig Tests', () {
    test('defaultTheme and copyWith', () {
      final theme = ThemeConfig.defaultTheme();
      expect(theme.name, 'Gaming Dashboard');

      final updated = theme.copyWith(
        name: 'New Custom Theme',
        accent: const Color(0xff00ff00),
      );
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

    test('advanced skinning fields round-trip through JSON', () {
      final theme = ThemeConfig.defaultTheme().copyWith(
        wallpaperPath: '/tmp/wall.png',
        wallpaperOpacity: 0.42,
        wallpaperBlur: 7.5,
        accentSecondary: const Color(0xff00f0ff),
        borderColor: const Color(0xff2d334d),
      );

      final restored = ThemeConfig.fromJson(theme.toJson());
      expect(restored.wallpaperPath, '/tmp/wall.png');
      expect(restored.wallpaperOpacity, closeTo(0.42, 1e-6));
      expect(restored.wallpaperBlur, closeTo(7.5, 1e-6));
      expect(restored.accentSecondary, const Color(0xff00f0ff));
      expect(restored.borderColor, const Color(0xff2d334d));
    });

    test('border falls back to translucent textSecondary when unset', () {
      final theme = ThemeConfig.defaultTheme();
      expect(theme.borderColor, isNull);
      expect(theme.border, theme.textSecondary.withValues(alpha: 0.2));
    });

    test('copyWith(clearWallpaper: true) drops the wallpaper path', () {
      final theme =
          ThemeConfig.defaultTheme().copyWith(wallpaperPath: '/tmp/a.png');
      expect(theme.copyWith(clearWallpaper: true).wallpaperPath, isNull);
    });

    test('wallpaper opacity and blur are clamped on decode', () {
      final restored = ThemeConfig.fromJson({
        'name': 'Clamp',
        'wallpaper_opacity': 5.0,
        'wallpaper_blur': 999.0,
      });
      expect(restored.wallpaperOpacity, 1.0);
      expect(restored.wallpaperBlur, 20.0);
    });

    test('empty wallpaper path decodes to null', () {
      final restored = ThemeConfig.fromJson({
        'name': 'No Wall',
        'wallpaper_path': '   ',
      });
      expect(restored.wallpaperPath, isNull);
    });
  });
}
