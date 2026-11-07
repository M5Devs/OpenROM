// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import 'theme_config.dart';

/// The `skin.json` (`.orskin` v2) / `theme.json` (v1) manifest embedded in an
/// `.orskin` bundle.
///
/// v2 schema:
/// ```json
/// {
///   "id": "my-theme",
///   "name": "My Theme Name",
///   "author": "Creator Name",
///   "version": "2.0.0",
///   "mode": "dark",
///   "hasCustomFont": true,
///   "fontFileName": "font.ttf",
///   "hasCustomIcons": true,
///   "hasCustomDropzone": true,
///   "hiddenTabs": ["dreamcast"],
///   "ui": { "borderRadius": 16.0, "wallpaperOpacity": 0.25, "wallpaperBlur": 2.0 },
///   "colors": { "background": "#120e1f", "...": "..." }
/// }
/// ```
///
/// v1 `theme.json` files (flat `borderRadius`/`wallpaperOpacity`/
/// `wallpaperBlur`, no `ui` block, no `specVersion`) still load: every v2 field
/// is optional and falls back to its v1 default.
///
/// OpenROM-specific extras the spec does not cover (`sidebarBg`, `terminalBg`,
/// `terminalText`, `fontFamily`, `layout`) are written under a namespaced
/// `"openrom"` object so a full [ThemeConfig] round-trips losslessly while
/// other readers can safely ignore them.
class SkinManifest {
  /// Current `.orskin` spec revision.
  static const int specVersion = 2;

  /// Canonical navigation tab ids. These are the keys used both by
  /// [hiddenTabs] and by the `icons/<id>.png` sidebar icon overrides.
  static const List<String> tabIds = <String>[
    'home',
    'patcher',
    'tools',
    'dreamcast',
    'plugins',
    'settings',
    'about',
    'theme',
  ];

  final String id;
  final String name;
  final String author;
  final String version;

  /// `"dark"` or `"light"`; drives which palette variant the skin is tuned for.
  final String mode;

  /// Whether the bundle ships a runtime-loaded custom font.
  final bool hasCustomFont;

  /// File name (relative to the bundle root) of the custom font, if any.
  final String? fontFileName;

  /// Whether the bundle ships `icons/<id>.png` sidebar overrides.
  final bool hasCustomIcons;

  /// Whether the bundle ships a `dropzone.gif`/`dropzone.png` illustration.
  final bool hasCustomDropzone;

  /// Navigation tab ids this skin hides (subset of [tabIds]).
  final List<String> hiddenTabs;

  /// The full palette and geometry this skin describes.
  final ThemeConfig theme;

  const SkinManifest({
    required this.id,
    required this.name,
    required this.author,
    required this.version,
    required this.mode,
    required this.theme,
    this.hasCustomFont = false,
    this.fontFileName,
    this.hasCustomIcons = false,
    this.hasCustomDropzone = false,
    this.hiddenTabs = const <String>[],
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
      'hasCustomFont': hasCustomFont,
      if (fontFileName != null) 'fontFileName': fontFileName,
      'hasCustomIcons': hasCustomIcons,
      'hasCustomDropzone': hasCustomDropzone,
      if (hiddenTabs.isNotEmpty) 'hiddenTabs': hiddenTabs,
      // v2 canonical geometry block.
      'ui': {
        'borderRadius': theme.borderRadius,
        'wallpaperOpacity': theme.wallpaperOpacity,
        'wallpaperBlur': theme.wallpaperBlur,
      },
      // v1-compatible flat geometry, so v1 readers still understand the file.
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
    // v2 nests geometry under "ui"; v1 kept it flat at the top level.
    final ui = (json['ui'] as Map?)?.cast<String, dynamic>() ?? const {};

    double? geometry(String key) {
      final v = ui[key] ?? json[key];
      return (v as num?)?.toDouble();
    }

    final hiddenTabs = ((json['hiddenTabs'] as List?) ?? const [])
        .map((e) => e.toString())
        .where(tabIds.contains)
        .toList(growable: false);

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
      borderRadius: (geometry('borderRadius') ?? 12.0).clamp(0.0, 24.0),
      layout: (extra['layout'] as String?) ?? fallback.layout,
      wallpaperOpacity: (geometry('wallpaperOpacity') ?? 0.15).clamp(0.0, 1.0),
      wallpaperBlur: (geometry('wallpaperBlur') ?? 0.0).clamp(0.0, 20.0),
      accentSecondary: _parseHex(colors['accentSecondary'], null),
      borderColor: _parseHex(colors['border'], null),
      skinId: json['id'] as String?,
      hiddenTabs: hiddenTabs,
    );

    final fontFileName = (json['fontFileName'] as String?)?.trim();

    return SkinManifest(
      id: (json['id'] as String?)?.trim().isNotEmpty == true
          ? json['id'] as String
          : 'custom-skin',
      name: theme.name,
      author: (json['author'] as String?) ?? 'Unknown',
      version: (json['version'] as String?) ?? '1.0.0',
      mode: (json['mode'] as String?) ?? 'dark',
      theme: theme,
      hasCustomFont: (json['hasCustomFont'] as bool?) ??
          (fontFileName != null && fontFileName.isNotEmpty),
      fontFileName: (fontFileName == null || fontFileName.isEmpty)
          ? null
          : p.basename(fontFileName.replaceAll('\\', '/')),
      hasCustomIcons: (json['hasCustomIcons'] as bool?) ?? false,
      hasCustomDropzone: (json['hasCustomDropzone'] as bool?) ?? false,
      hiddenTabs: hiddenTabs,
    );
  }

  /// Builds a manifest from an in-editor [theme], filling in the metadata the
  /// `.orskin` spec requires. Asset flags are derived from the theme's resolved
  /// asset paths.
  factory SkinManifest.fromTheme(
    ThemeConfig theme, {
    String? id,
    String? author,
    String? version,
  }) {
    final fontFileName = theme.fontPath == null
        ? null
        : p.basename(theme.fontPath!.replaceAll('\\', '/'));
    return SkinManifest(
      id: id ?? _slugify(theme.name),
      name: theme.name,
      author: author ?? 'OpenROM User',
      version: version ?? '1.0.0',
      mode: theme.isLight ? 'light' : 'dark',
      theme: theme,
      hasCustomFont: fontFileName != null && fontFileName.isNotEmpty,
      fontFileName: fontFileName,
      hasCustomIcons: theme.iconDir != null,
      hasCustomDropzone: theme.dropzonePath != null,
      hiddenTabs:
          theme.hiddenTabs.where(tabIds.contains).toList(growable: false),
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
    bool? hasCustomFont,
    String? fontFileName,
    bool clearFontFileName = false,
    bool? hasCustomIcons,
    bool? hasCustomDropzone,
    List<String>? hiddenTabs,
  }) {
    return SkinManifest(
      id: id ?? this.id,
      name: name ?? this.name,
      author: author ?? this.author,
      version: version ?? this.version,
      mode: mode ?? this.mode,
      theme: theme ?? this.theme,
      hasCustomFont: hasCustomFont ?? this.hasCustomFont,
      fontFileName:
          clearFontFileName ? null : (fontFileName ?? this.fontFileName),
      hasCustomIcons: hasCustomIcons ?? this.hasCustomIcons,
      hasCustomDropzone: hasCustomDropzone ?? this.hasCustomDropzone,
      hiddenTabs: hiddenTabs ?? this.hiddenTabs,
    );
  }
}
