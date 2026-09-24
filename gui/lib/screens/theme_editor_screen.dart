// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'package:flutter/material.dart';
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

  // Opens a simple HSV color picker dialog and returns the picked color
  Future<void> _pickColor(Color initial, void Function(Color) onPicked) async {
    Color temp = initial;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.theme.surface,
        title: Text('Pick Color', style: TextStyle(color: widget.theme.textPrimary)),
        content: SizedBox(
          width: 300,
          child: StatefulBuilder(
            builder: (ctx, setInner) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Hue slider
                _buildSlider('Hue', HSVColor.fromColor(temp).hue, 0, 360, (v) {
                  setInner(() {
                    temp = HSVColor.fromColor(temp).withHue(v).toColor();
                  });
                }, temp),
                _buildSlider('Saturation', HSVColor.fromColor(temp).saturation, 0, 1, (v) {
                  setInner(() {
                    temp = HSVColor.fromColor(temp).withSaturation(v).toColor();
                  });
                }, temp),
                _buildSlider('Value', HSVColor.fromColor(temp).value, 0, 1, (v) {
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
            child: Text('Cancel', style: TextStyle(color: widget.theme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: widget.theme.accent),
            onPressed: () {
              Navigator.pop(ctx);
              onPicked(temp);
            },
            child: const Text('Apply', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(String label, double value, double min, double max,
      void Function(double) onChanged, Color previewColor) {
    return Row(
      children: [
        SizedBox(width: 90, child: Text(label, style: TextStyle(color: widget.theme.textPrimary, fontSize: 12))),
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

  // One color row: label + swatch button
  Widget _buildColorRow(String label, Color current, void Function(Color) onPicked) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(label, style: TextStyle(color: _edited.textPrimary, fontSize: 14)),
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
            style: TextStyle(color: _edited.textSecondary, fontFamily: 'monospace', fontSize: 12),
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
                        Text('game.iso', style: TextStyle(color: t.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
                        Text('→ CHD · 700 MB', style: TextStyle(color: t.textSecondary, fontSize: 10)),
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
                      style: TextStyle(color: t.terminalText, fontSize: 9, fontFamily: 'monospace'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Accent button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: t.accent,
                      borderRadius: BorderRadius.circular(t.borderRadius / 2),
                    ),
                    child: Text('Convert', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
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
          Text('Theme Editor', style: TextStyle(color: t.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
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
                    Text('Theme Name', style: TextStyle(color: t.accent, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      style: TextStyle(color: _edited.textPrimary),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: t.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(t.borderRadius),
                          borderSide: BorderSide(color: t.accent.withValues(alpha: 0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(t.borderRadius),
                          borderSide: BorderSide(color: t.accent.withValues(alpha: 0.3)),
                        ),
                      ),
                      onChanged: (v) => setState(() {
                        _edited = _edited.copyWith(name: v);
                      }),
                    ),
                    const SizedBox(height: 20),
                    Text('Colors', style: TextStyle(color: t.accent, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildColorRow('Background', _edited.background, (c) => _edited = _edited.copyWith(background: c)),
                    _buildColorRow('Surface', _edited.surface, (c) => _edited = _edited.copyWith(surface: c)),
                    _buildColorRow('Accent', _edited.accent, (c) => _edited = _edited.copyWith(accent: c)),
                    _buildColorRow('Text Primary', _edited.textPrimary, (c) => _edited = _edited.copyWith(textPrimary: c)),
                    _buildColorRow('Text Secondary', _edited.textSecondary, (c) => _edited = _edited.copyWith(textSecondary: c)),
                    _buildColorRow('Sidebar Background', _edited.sidebarBg, (c) => _edited = _edited.copyWith(sidebarBg: c)),
                    _buildColorRow('Card Background', _edited.cardBg, (c) => _edited = _edited.copyWith(cardBg: c)),
                    _buildColorRow('Terminal Background', _edited.terminalBg, (c) => _edited = _edited.copyWith(terminalBg: c)),
                    _buildColorRow('Terminal Text', _edited.terminalText, (c) => _edited = _edited.copyWith(terminalText: c)),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text('Save Theme', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: t.accent),
                      onPressed: () async {
                        final saved = _edited.copyWith(name: _nameController.text.trim().isEmpty ? 'Custom Theme' : _nameController.text.trim());
                        await widget.themeService.saveCustomTheme(saved);
                        await widget.themeService.setTheme(saved);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Theme "${saved.name}" saved!')),
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
                  Text('Live Preview', style: TextStyle(color: t.accent, fontSize: 14, fontWeight: FontWeight.bold)),
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
