// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

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
  Color get border => textSecondary.withValues(alpha: 0.2);

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

  /// Converts a Color to a 6-char hex string e.g. '#e94560'
  static String _colorToHex(Color color) {
    return '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'background': _colorToHex(background),
      'surface': _colorToHex(surface),
      'accent': _colorToHex(accent),
      'text_primary': _colorToHex(textPrimary),
      'text_secondary': _colorToHex(textSecondary),
      'sidebar_bg': _colorToHex(sidebarBg),
      'card_bg': _colorToHex(cardBg),
      'terminal_bg': _colorToHex(terminalBg),
      'terminal_text': _colorToHex(terminalText),
      'font_family': fontFamily,
      'border_radius': borderRadius,
      'layout': layout,
    };
  }

  ThemeConfig copyWith({
    String? name,
    Color? background,
    Color? surface,
    Color? accent,
    Color? textPrimary,
    Color? textSecondary,
    Color? sidebarBg,
    Color? cardBg,
    Color? terminalBg,
    Color? terminalText,
    String? fontFamily,
    double? borderRadius,
    String? layout,
  }) {
    return ThemeConfig(
      name: name ?? this.name,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      accent: accent ?? this.accent,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      sidebarBg: sidebarBg ?? this.sidebarBg,
      cardBg: cardBg ?? this.cardBg,
      terminalBg: terminalBg ?? this.terminalBg,
      terminalText: terminalText ?? this.terminalText,
      fontFamily: fontFamily ?? this.fontFamily,
      borderRadius: borderRadius ?? this.borderRadius,
      layout: layout ?? this.layout,
    );
  }

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
      background: hexToColor(
        json['background'] ?? '#0d0d0d',
        const Color(0xff0d0d0d),
      ),
      surface: hexToColor(
        json['surface'] ?? '#1a1a1a',
        const Color(0xff1a1a1a),
      ),
      accent: hexToColor(json['accent'] ?? '#e94560', const Color(0xffe94560)),
      textPrimary: hexToColor(
        json['text_primary'] ?? '#ffffff',
        const Color(0xffffffff),
      ),
      textSecondary: hexToColor(
        json['text_secondary'] ?? '#a0a0b0',
        const Color(0xffa0a0b0),
      ),
      sidebarBg: hexToColor(
        json['sidebar_bg'] ?? '#111111',
        const Color(0xff111111),
      ),
      cardBg: hexToColor(json['card_bg'] ?? '#1e1e1e', const Color(0xff1e1e1e)),
      terminalBg: hexToColor(
        json['terminal_bg'] ?? '#0a0a0a',
        const Color(0xff0a0a0a),
      ),
      terminalText: hexToColor(
        json['terminal_text'] ?? '#00e676',
        const Color(0xff00e676),
      ),
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
