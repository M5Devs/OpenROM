// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/skin_manifest.dart';
import '../models/theme_config.dart';
import '../services/theme_service.dart';

class ThemeEditorScreen extends StatefulWidget {
  final ThemeConfig theme;
  final ThemeService themeService;

  const ThemeEditorScreen({
    super.key,
    required this.theme,
    required this.themeService,
  });

  @override
  State<ThemeEditorScreen> createState() => _ThemeEditorScreenState();
}

class _ThemeEditorScreenState extends State<ThemeEditorScreen> {
  late ThemeConfig _edited;
  late TextEditingController _nameController;

  AppLocalizations get _l10n => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    _edited = widget.themeService.currentTheme;
    _nameController = TextEditingController(text: _edited.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Applies the in-progress edits to the live theme service.
  ThemeConfig _currentEdits() => _edited.copyWith(
        name: _nameController.text.trim().isEmpty
            ? 'Custom Skin'
            : _nameController.text.trim(),
      );

  Future<void> _pickWallpaper() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['gif', 'png', 'jpg', 'jpeg', 'webp'],
      dialogTitle: _l10n.themePickWallpaper,
    );
    final path = result?.files.single.path;
    if (path == null) return;
    setState(() => _edited = _edited.copyWith(wallpaperPath: path));
  }

  Future<void> _pickDropzone() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['gif', 'png'],
      dialogTitle: _l10n.themePickDropzone,
    );
    final path = result?.files.single.path;
    if (path == null) return;
    setState(() => _edited = _edited.copyWith(dropzonePath: path));
  }

  Future<void> _pickFont() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['ttf', 'otf'],
      dialogTitle: _l10n.themePickFont,
    );
    final path = result?.files.single.path;
    if (path == null) return;
    setState(() => _edited = _edited.copyWith(fontPath: path));
  }

  void _toggleHiddenTab(String tabId) {
    setState(() {
      final next = _edited.hiddenTabs.toList();
      if (next.contains(tabId)) {
        next.remove(tabId);
      } else {
        next.add(tabId);
      }
      _edited = _edited.copyWith(hiddenTabs: next);
    });
  }

  Future<void> _importSkin() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['orskin'],
      dialogTitle: _l10n.themeImportSkinBundle,
    );
    final path = result?.files.single.path;
    if (path == null) return;

    final imported = await widget.themeService.importSkin(File(path));
    if (!imported.isOk) {
      _snack(_l10n.themeImportFailed('${imported.error}'));
      return;
    }
    setState(() {
      _edited = imported.value!.theme;
      _nameController.text = _edited.name;
    });
    _snack(_l10n.themeImported(imported.value!.name));
  }

  Future<void> _exportSkin() async {
    final theme = _currentEdits();
    final suggested = '${theme.name.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')}'
        '.orskin';
    final out = await FilePicker.platform.saveFile(
      dialogTitle: _l10n.themeExportSkinBundle,
      fileName: suggested,
      type: FileType.custom,
      allowedExtensions: const ['orskin'],
    );
    if (out == null) return;

    // Assets are resolved from the theme's own paths, so every picked file is
    // packed automatically.
    final exported = widget.themeService.exportSkin(
      theme: theme,
      outputPath: File(out),
      wallpaper: _fileOrNull(theme.wallpaperPath),
      dropzone: _fileOrNull(theme.dropzonePath),
      font: _fileOrNull(theme.fontPath),
    );
    if (!exported.isOk) {
      _snack(_l10n.themeExportFailed('${exported.error}'));
      return;
    }
    _snack(_l10n.themeExported(exported.value!.path));
  }

  static File? _fileOrNull(String? path) {
    if (path == null || path.isEmpty) return null;
    final file = File(path);
    return file.existsSync() ? file : null;
  }

  // Opens a simple HSV color picker dialog and returns the picked color
  Future<void> _pickColor(Color initial, void Function(Color) onPicked) async {
    Color temp = initial;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.theme.surface,
        title: Text(
          _l10n.themePickColor,
          style: TextStyle(color: widget.theme.textPrimary),
        ),
        content: SizedBox(
          width: 300,
          child: StatefulBuilder(
            builder: (ctx, setInner) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Hue slider
                _buildSlider(
                    _l10n.themeHue, HSVColor.fromColor(temp).hue, 0, 360, (v) {
                  setInner(() {
                    temp = HSVColor.fromColor(temp).withHue(v).toColor();
                  });
                }, temp),
                _buildSlider(
                  _l10n.themeSaturation,
                  HSVColor.fromColor(temp).saturation,
                  0,
                  1,
                  (v) {
                    setInner(() {
                      temp = HSVColor.fromColor(
                        temp,
                      ).withSaturation(v).toColor();
                    });
                  },
                  temp,
                ),
                _buildSlider(
                    _l10n.themeValue, HSVColor.fromColor(temp).value, 0, 1, (
                  v,
                ) {
                  setInner(() {
                    temp = HSVColor.fromColor(temp).withValue(v).toColor();
                  });
                }, temp),
                const SizedBox(height: 16),
                Container(
                  height: 48,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: temp,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              _l10n.commonCancel,
              style: TextStyle(color: widget.theme.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.theme.accent,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onPicked(temp);
            },
            child: Text(_l10n.commonApply,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    void Function(double) onChanged,
    Color previewColor,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(color: widget.theme.textPrimary, fontSize: 12),
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            activeColor: previewColor,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  // One asset picker row: a "Choose …" button plus a Remove button when set.
  Widget _assetPickerRow(
    ThemeConfig t, {
    required IconData icon,
    required String label,
    required String? current,
    required VoidCallback onPick,
    required VoidCallback onClear,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          OutlinedButton.icon(
            icon: Icon(icon),
            label: Text(label),
            style: OutlinedButton.styleFrom(foregroundColor: t.accent),
            onPressed: onPick,
          ),
          const SizedBox(width: 12),
          if (current != null) ...[
            Flexible(
              child: Text(
                current.split(Platform.pathSeparator).last,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: t.textSecondary, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              icon: const Icon(Icons.clear),
              label: Text(_l10n.commonRemove),
              style: TextButton.styleFrom(foregroundColor: t.textSecondary),
              onPressed: onClear,
            ),
          ],
        ],
      ),
    );
  }

  // One color row: label + swatch button
  Widget _buildColorRow(
    String label,
    Color current,
    void Function(Color) onPicked,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: TextStyle(color: _edited.textPrimary, fontSize: 14),
            ),
          ),
          GestureDetector(
            onTap: () => _pickColor(current, (c) {
              setState(() => onPicked(c));
            }),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: current,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '#${(current.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}',
            style: TextStyle(
              color: _edited.textSecondary,
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Live preview panel
  Widget _buildPreview() {
    final t = _edited;
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: t.background,
        borderRadius: BorderRadius.circular(t.borderRadius),
        border: Border.all(color: t.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          // Sidebar strip
          Container(
            width: 40,
            color: t.sidebarBg,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.hexagon, color: t.accent, size: 20),
                const SizedBox(height: 16),
                Icon(Icons.queue_music, color: t.accent, size: 16),
                const SizedBox(height: 12),
                Icon(Icons.settings, color: t.textSecondary, size: 16),
                const SizedBox(height: 12),
                Icon(Icons.palette, color: t.textSecondary, size: 16),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card block
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: t.cardBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'game.iso',
                          style: TextStyle(
                            color: t.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '→ CHD · 700 MB',
                          style: TextStyle(
                            color: t.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Terminal block
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: t.terminalBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '> chdman createcd ...\n✓ Done in 3.2s',
                      style: TextStyle(
                        color: t.terminalText,
                        fontSize: 9,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Accent button
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: t.accent,
                      borderRadius: BorderRadius.circular(t.borderRadius / 2),
                    ),
                    child: Text(
                      _l10n.convertButton,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme; // base theme for chrome

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _l10n.themeEditorTitle,
            style: TextStyle(
              color: t.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: controls
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Theme name field
                    Text(
                      _l10n.themeThemeName,
                      style: TextStyle(
                        color: t.accent,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      style: TextStyle(color: _edited.textPrimary),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: t.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(t.borderRadius),
                          borderSide: BorderSide(
                            color: t.accent.withValues(alpha: 0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(t.borderRadius),
                          borderSide: BorderSide(
                            color: t.accent.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      onChanged: (v) => setState(() {
                        _edited = _edited.copyWith(name: v);
                      }),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.file_download_outlined),
                          label: Text(_l10n.themeImportShort),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: t.accent,
                          ),
                          onPressed: _importSkin,
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.file_upload_outlined),
                          label: Text(_l10n.themeExportShort),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: t.accent,
                          ),
                          onPressed: _exportSkin,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _l10n.themeColors,
                      style: TextStyle(
                        color: t.accent,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildColorRow(
                      _l10n.themeBackground,
                      _edited.background,
                      (c) => _edited = _edited.copyWith(background: c),
                    ),
                    _buildColorRow(
                      _l10n.themeSurface,
                      _edited.surface,
                      (c) => _edited = _edited.copyWith(surface: c),
                    ),
                    _buildColorRow(
                      _l10n.themeAccent,
                      _edited.accent,
                      (c) => _edited = _edited.copyWith(accent: c),
                    ),
                    _buildColorRow(
                      _l10n.themeTextPrimary,
                      _edited.textPrimary,
                      (c) => _edited = _edited.copyWith(textPrimary: c),
                    ),
                    _buildColorRow(
                      _l10n.themeTextSecondary,
                      _edited.textSecondary,
                      (c) => _edited = _edited.copyWith(textSecondary: c),
                    ),
                    _buildColorRow(
                      _l10n.themeSidebarBg,
                      _edited.sidebarBg,
                      (c) => _edited = _edited.copyWith(sidebarBg: c),
                    ),
                    _buildColorRow(
                      _l10n.themeCardBg,
                      _edited.cardBg,
                      (c) => _edited = _edited.copyWith(cardBg: c),
                    ),
                    _buildColorRow(
                      _l10n.themeTerminalBg,
                      _edited.terminalBg,
                      (c) => _edited = _edited.copyWith(terminalBg: c),
                    ),
                    _buildColorRow(
                      _l10n.themeTerminalText,
                      _edited.terminalText,
                      (c) => _edited = _edited.copyWith(terminalText: c),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _l10n.themeGeometry,
                      style: TextStyle(
                        color: t.accent,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSlider(
                      _l10n.themeCornerRadius,
                      _edited.borderRadius,
                      0,
                      24,
                      (v) => setState(
                        () => _edited = _edited.copyWith(borderRadius: v),
                      ),
                      t.accent,
                    ),
                    _buildSlider(
                      _l10n.themeWallpaperOpacity,
                      _edited.wallpaperOpacity,
                      0,
                      1,
                      (v) => setState(
                        () => _edited = _edited.copyWith(wallpaperOpacity: v),
                      ),
                      t.accent,
                    ),
                    _buildSlider(
                      _l10n.themeWallpaperBlur,
                      _edited.wallpaperBlur,
                      0,
                      20,
                      (v) => setState(
                        () => _edited = _edited.copyWith(wallpaperBlur: v),
                      ),
                      t.accent,
                    ),
                    const SizedBox(height: 8),
                    _assetPickerRow(
                      t,
                      icon: Icons.wallpaper,
                      label: _l10n.themeChooseWallpaper,
                      current: _edited.wallpaperPath,
                      onPick: _pickWallpaper,
                      onClear: () => setState(
                        () => _edited = _edited.copyWith(clearWallpaper: true),
                      ),
                    ),
                    _assetPickerRow(
                      t,
                      icon: Icons.animation,
                      label: _l10n.themeChooseDropzone,
                      current: _edited.dropzonePath,
                      onPick: _pickDropzone,
                      onClear: () => setState(
                        () => _edited = _edited.copyWith(clearDropzone: true),
                      ),
                    ),
                    _assetPickerRow(
                      t,
                      icon: Icons.text_fields,
                      label: _l10n.themeChooseFont,
                      current: _edited.fontPath,
                      onPick: _pickFont,
                      onClear: () => setState(
                        () => _edited = _edited.copyWith(clearFont: true),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _l10n.themeSidebarTabs,
                      style: TextStyle(
                        color: t.accent,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _l10n.themeSidebarTabsHelp,
                      style: TextStyle(color: t.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        for (final tab in SkinManifest.tabIds)
                          SizedBox(
                            width: 150,
                            child: CheckboxListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              value: !_edited.hiddenTabs.contains(tab),
                              activeColor: t.accent,
                              title: Text(
                                tab[0].toUpperCase() + tab.substring(1),
                                style: TextStyle(
                                  color: t.textPrimary,
                                  fontSize: 13,
                                ),
                              ),
                              onChanged: (_) => _toggleHiddenTab(tab),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: Text(
                        _l10n.themeSaveTheme,
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: t.accent,
                      ),
                      onPressed: () async {
                        final saved = _edited.copyWith(
                          name: _nameController.text.trim().isEmpty
                              ? 'Custom Theme'
                              : _nameController.text.trim(),
                        );
                        await widget.themeService.saveCustomTheme(saved);
                        await widget.themeService.setTheme(saved);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_l10n.themeSaved(saved.name)),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 40),
              // Right: live preview
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _l10n.themeLivePreview,
                    style: TextStyle(
                      color: t.accent,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(height: 280, child: _buildPreview()),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
