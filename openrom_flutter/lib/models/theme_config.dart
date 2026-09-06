// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3 + Commons Clause

import 'package:flutter/material.dart';

class ThemeConfig {
  final String name;
  final Color background;
  final Color surface;
  final Color accent;
  final Color textPrimary;
  final Color textSecondary;
  final Color sidebarBg;
  final Color cardBg;
  final Color terminalBg;
  final Color terminalText;
  final String fontFamily;
  final double borderRadius;
  final String layout;

  ThemeConfig({
    required this.name,
    required this.background,
    required this.surface,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.sidebarBg,
    required this.cardBg,
    required this.terminalBg,
    required this.terminalText,
    required this.fontFamily,
    required this.borderRadius,
    required this.layout,
  });

  factory ThemeConfig.fromJson(Map<String, dynamic> json) {
    Color hexToColor(String hex, Color defaultColor) {
      try {
        final buffer = StringBuffer();
        if (hex.length == 6 || hex.length == 7) buffer.write('ff');
        buffer.write(hex.replaceFirst('#', ''));
        return Color(int.parse(buffer.toString(), radix: 16));
      } catch (_) {
        return defaultColor;
      }
    }

    return ThemeConfig(
      name: json['name'] ?? 'Custom Theme',
      background: hexToColor(json['background'] ?? '#0d0d0d', const Color(0xff0d0d0d)),
      surface: hexToColor(json['surface'] ?? '#1a1a1a', const Color(0xff1a1a1a)),
      accent: hexToColor(json['accent'] ?? '#e94560', const Color(0xffe94560)),
      textPrimary: hexToColor(json['text_primary'] ?? '#ffffff', const Color(0xffffffff)),
      textSecondary: hexToColor(json['text_secondary'] ?? '#a0a0b0', const Color(0xffa0a0b0)),
      sidebarBg: hexToColor(json['sidebar_bg'] ?? '#111111', const Color(0xff111111)),
      cardBg: hexToColor(json['card_bg'] ?? '#1e1e1e', const Color(0xff1e1e1e)),
      terminalBg: hexToColor(json['terminal_bg'] ?? '#0a0a0a', const Color(0xff0a0a0a)),
      terminalText: hexToColor(json['terminal_text'] ?? '#00e676', const Color(0xff00e676)),
      fontFamily: json['font_family'] ?? 'Sans-Serif',
      borderRadius: (json['border_radius'] as num?)?.toDouble() ?? 12.0,
      layout: json['layout'] ?? 'sidebar_left',
    );
  }

  factory ThemeConfig.defaultTheme() {
    return ThemeConfig(
      name: 'Gaming Dashboard',
      background: const Color(0xff0d0d0d),
      surface: const Color(0xff1a1a1a),
      accent: const Color(0xffe94560),
      textPrimary: const Color(0xffffffff),
      textSecondary: const Color(0xffa0a0b0),
      sidebarBg: const Color(0xff111111),
      cardBg: const Color(0xff1e1e1e),
      terminalBg: const Color(0xff0a0a0a),
      terminalText: const Color(0xff00e676),
      fontFamily: 'Inter',
      borderRadius: 12.0,
      layout: 'sidebar_left',
    );
  }
}
