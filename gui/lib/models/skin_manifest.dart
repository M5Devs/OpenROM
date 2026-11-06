// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'package:flutter/material.dart';

import 'theme_config.dart';

/// The `theme.json` manifest embedded in an `.orskin` bundle.
///
/// The on-disk schema is the public OpenROM skin specification:
///
/// ```json
/// {
///   "id": "cyberpunk-neon",
///   "name": "Cyberpunk Neon",
///   "author": "Claus Valca",
///   "version": "1.0.0",
///   "mode": "dark",
///   "borderRadius": 12.0,
///   "wallpaperOpacity": 0.20,
///   "wallpaperBlur": 5.0,
///   "colors": {
///     "background": "#0d0e15",
///     "surface": "#161926",
///     "card": "#1e2235",
///     "accent": "#e94560",
///     "accentSecondary": "#00f0ff",
///     "text": "#ffffff",
///     "textMuted": "#8b949e",
///     "border": "#2d334d"
///   }
/// }
/// ```
///
/// OpenROM-specific extras that the spec does not cover (`sidebarBg`,
/// `terminalBg`, `terminalText`, `fontFamily`, `layout`) are written under a
/// namespaced `"openrom"` object so that a full [ThemeConfig] round-trips
/// losslessly while other readers can safely ignore them.
class SkinManifest {
  /// Current `.orskin` spec revision.
  static const int specVersion = 1;

  final String id;
  final String name;
  final String author;
  final String version;

  /// `"dark"` or `"light"`; drives which palette variant the skin is tuned for.
  final String mode;

  /// The full palette and geometry this skin describes.
  final ThemeConfig theme;

  const SkinManifest({
    required this.id,
    required this.name,
    required this.author,
    required this.version,
    required this.mode,
    required this.theme,
  });

  bool get isDark => mode != 'light';

  static String _hex(Color color) =>
      '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  static Color? _parseHex(Object? value, Color? fallback) {
    if (value is! String) return fallback;
    var hex = value.trim().replaceFirst('#', '');
    if (hex.length == 6) hex = 'ff$hex';
    if (hex.length != 8) return fallback;
    final parsed = int.tryParse(hex, radix: 16);
    return parsed == null ? fallback : Color(parsed);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'author': author,
      'version': version,
      'mode': mode,
      'specVersion': specVersion,
      'borderRadius': theme.borderRadius,
      'wallpaperOpacity': theme.wallpaperOpacity,
      'wallpaperBlur': theme.wallpaperBlur,
      'colors': {
        'background': _hex(theme.background),
        'surface': _hex(theme.surface),
        'card': _hex(theme.cardBg),
        'accent': _hex(theme.accent),
        if (theme.accentSecondary != null)
          'accentSecondary': _hex(theme.accentSecondary!),
        'text': _hex(theme.textPrimary),
        'textMuted': _hex(theme.textSecondary),
        if (theme.borderColor != null) 'border': _hex(theme.borderColor!),
      },
      'openrom': {
        'sidebarBg': _hex(theme.sidebarBg),
        'terminalBg': _hex(theme.terminalBg),
        'terminalText': _hex(theme.terminalText),
        'fontFamily': theme.fontFamily,
        'layout': theme.layout,
      },
    };
  }

  factory SkinManifest.fromJson(Map<String, dynamic> json) {
    final colors =
        (json['colors'] as Map?)?.cast<String, dynamic>() ?? const {};
    final extra =
        (json['openrom'] as Map?)?.cast<String, dynamic>() ?? const {};

    final fallback = ThemeConfig.defaultTheme();
    final background = _parseHex(colors['background'], fallback.background)!;
    final surface = _parseHex(colors['surface'], fallback.surface)!;
    final accent = _parseHex(colors['accent'], fallback.accent)!;
    final text = _parseHex(colors['text'], fallback.textPrimary)!;
    final muted = _parseHex(colors['textMuted'], fallback.textSecondary)!;

    final theme = ThemeConfig(
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? json['name'] as String
          : 'Custom Skin',
      background: background,
      surface: surface,
      accent: accent,
      textPrimary: text,
      textSecondary: muted,
      sidebarBg: _parseHex(extra['sidebarBg'], surface)!,
      cardBg: _parseHex(colors['card'], fallback.cardBg)!,
      terminalBg: _parseHex(extra['terminalBg'], fallback.terminalBg)!,
      terminalText: _parseHex(extra['terminalText'], fallback.terminalText)!,
      fontFamily: (extra['fontFamily'] as String?) ?? fallback.fontFamily,
      borderRadius:
          ((json['borderRadius'] as num?)?.toDouble() ?? 12.0).clamp(0.0, 24.0),
      layout: (extra['layout'] as String?) ?? fallback.layout,
      wallpaperOpacity:
          ((json['wallpaperOpacity'] as num?)?.toDouble() ?? 0.15).clamp(
        0.0,
        1.0,
      ),
      wallpaperBlur:
          ((json['wallpaperBlur'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 20.0),
      accentSecondary: _parseHex(colors['accentSecondary'], null),
      borderColor: _parseHex(colors['border'], null),
      skinId: json['id'] as String?,
    );

    return SkinManifest(
      id: (json['id'] as String?)?.trim().isNotEmpty == true
          ? json['id'] as String
          : 'custom-skin',
      name: theme.name,
      author: (json['author'] as String?) ?? 'Unknown',
      version: (json['version'] as String?) ?? '1.0.0',
      mode: (json['mode'] as String?) ?? 'dark',
      theme: theme,
    );
  }

  /// Builds a manifest from an in-editor [theme], filling in the metadata the
  /// `.orskin` spec requires.
  factory SkinManifest.fromTheme(
    ThemeConfig theme, {
    String? id,
    String? author,
    String? version,
  }) {
    return SkinManifest(
      id: id ?? _slugify(theme.name),
      name: theme.name,
      author: author ?? 'OpenROM User',
      version: version ?? '1.0.0',
      mode: theme.isLight ? 'light' : 'dark',
      theme: theme,
    );
  }

  /// A filesystem-safe id derived from [value] (`[a-z0-9_-]` only).
  static String _slugify(String value) {
    final lowered = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final trimmed = lowered.replaceAll(RegExp(r'^-+|-+$'), '');
    return trimmed.isEmpty ? 'custom-skin' : trimmed;
  }

  /// Sanitises an arbitrary (possibly hostile) skin id into a safe directory
  /// name. Never returns an empty string or anything containing a path
  /// separator.
  static String sanitizeId(String raw) => _slugify(raw);

  SkinManifest copyWith({
    String? id,
    String? name,
    String? author,
    String? version,
    String? mode,
    ThemeConfig? theme,
  }) {
    return SkinManifest(
      id: id ?? this.id,
      name: name ?? this.name,
      author: author ?? this.author,
      version: version ?? this.version,
      mode: mode ?? this.mode,
      theme: theme ?? this.theme,
    );
  }
}
