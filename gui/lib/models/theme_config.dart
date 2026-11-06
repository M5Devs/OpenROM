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

  /// Absolute path to an installed wallpaper image, or null for a flat
  /// background. Only ever set for skins imported from `.orskin` bundles or
  /// chosen in the Theme Editor.
  final String? wallpaperPath;

  /// Opacity of the wallpaper layer, 0.0–1.0. Defaults to a subtle 0.15.
  final double wallpaperOpacity;

  /// Gaussian blur radius (logical px) applied to the wallpaper, 0.0–20.0.
  final double wallpaperBlur;

  /// Identifier of the `.orskin` this palette came from, if any.
  final String? skinId;

  /// Optional second accent (the `.orskin` spec's `accentSecondary`).
  final Color? accentSecondary;

  /// Optional explicit border colour (the `.orskin` spec's `border`). When
  /// null, [border] falls back to a translucent [textSecondary].
  final Color? borderColor;

  Color get border => borderColor ?? textSecondary.withValues(alpha: 0.2);

  /// Whether this palette is a light theme (light background, dark text).
  bool get isLight => background.computeLuminance() > 0.5;

  /// Returns a light-mode variant of this palette that keeps the same [name],
  /// accent and geometry so theme selection and persistence stay stable.
  ThemeConfig toLight() {
    return ThemeConfig(
      name: name,
      background: const Color(0xfff4f5f7),
      surface: const Color(0xffffffff),
      accent: accent,
      textPrimary: const Color(0xff1a1a1f),
      textSecondary: const Color(0xff5c5c66),
      sidebarBg: const Color(0xffe9eaee),
      cardBg: const Color(0xffffffff),
      terminalBg: const Color(0xff1c1f26),
      terminalText: const Color(0xff4ade80),
      fontFamily: fontFamily,
      borderRadius: borderRadius,
      layout: layout,
      wallpaperPath: wallpaperPath,
      wallpaperOpacity: wallpaperOpacity,
      wallpaperBlur: wallpaperBlur,
      skinId: skinId,
      accentSecondary: accentSecondary,
      borderColor: borderColor,
    );
  }

  /// Returns a dark-mode variant of this palette that keeps the same [name].
  ThemeConfig toDark() {
    return ThemeConfig(
      name: name,
      background: const Color(0xff0d0d0d),
      surface: const Color(0xff1a1a1a),
      accent: accent,
      textPrimary: const Color(0xffffffff),
      textSecondary: const Color(0xffa0a0b0),
      sidebarBg: const Color(0xff111111),
      cardBg: const Color(0xff1e1e1e),
      terminalBg: const Color(0xff0a0a0a),
      terminalText: const Color(0xff00e676),
      fontFamily: fontFamily,
      borderRadius: borderRadius,
      layout: layout,
      wallpaperPath: wallpaperPath,
      wallpaperOpacity: wallpaperOpacity,
      wallpaperBlur: wallpaperBlur,
      skinId: skinId,
      accentSecondary: accentSecondary,
      borderColor: borderColor,
    );
  }

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
    this.wallpaperPath,
    this.wallpaperOpacity = 0.15,
    this.wallpaperBlur = 0.0,
    this.skinId,
    this.accentSecondary,
    this.borderColor,
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
      if (wallpaperPath != null) 'wallpaper_path': wallpaperPath,
      'wallpaper_opacity': wallpaperOpacity,
      'wallpaper_blur': wallpaperBlur,
      if (skinId != null) 'skin_id': skinId,
      if (accentSecondary != null)
        'accent_secondary': _colorToHex(accentSecondary!),
      if (borderColor != null) 'border_color': _colorToHex(borderColor!),
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
    String? wallpaperPath,
    bool clearWallpaper = false,
    double? wallpaperOpacity,
    double? wallpaperBlur,
    String? skinId,
    Color? accentSecondary,
    Color? borderColor,
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
      wallpaperPath:
          clearWallpaper ? null : (wallpaperPath ?? this.wallpaperPath),
      wallpaperOpacity: wallpaperOpacity ?? this.wallpaperOpacity,
      wallpaperBlur: wallpaperBlur ?? this.wallpaperBlur,
      skinId: skinId ?? this.skinId,
      accentSecondary: accentSecondary ?? this.accentSecondary,
      borderColor: borderColor ?? this.borderColor,
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

    final accent =
        hexToColor(json['accent'] ?? '#e94560', const Color(0xffe94560));
    final textSecondary = hexToColor(
      json['text_secondary'] ?? '#a0a0b0',
      const Color(0xffa0a0b0),
    );

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
      accent: accent,
      textPrimary: hexToColor(
        json['text_primary'] ?? '#ffffff',
        const Color(0xffffffff),
      ),
      textSecondary: textSecondary,
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
      wallpaperPath: (json['wallpaper_path'] as String?)?.trim().isEmpty ?? true
          ? null
          : json['wallpaper_path'] as String,
      wallpaperOpacity:
          (json['wallpaper_opacity'] as num?)?.toDouble().clamp(0.0, 1.0) ??
              0.15,
      wallpaperBlur:
          (json['wallpaper_blur'] as num?)?.toDouble().clamp(0.0, 20.0) ?? 0.0,
      skinId: json['skin_id'] as String?,
      accentSecondary: json['accent_secondary'] == null
          ? null
          : hexToColor(json['accent_secondary'], accent),
      borderColor: json['border_color'] == null
          ? null
          : hexToColor(json['border_color'], textSecondary),
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
