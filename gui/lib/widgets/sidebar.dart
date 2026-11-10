// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../l10n/app_localizations.dart';
import '../models/theme_config.dart';

/// One sidebar destination. [index] is the absolute screen index (matching
/// `SkinManifest.tabIds`), which stays stable even when a skin hides tabs.
class _NavItem {
  final int index;
  final String id;
  final IconData icon;
  final String tooltip;

  const _NavItem({
    required this.index,
    required this.id,
    required this.icon,
    required this.tooltip,
  });
}

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int index) onDestinationSelected;
  final ThemeConfig theme;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final all = <_NavItem>[
      _NavItem(
        index: 0,
        id: 'home',
        icon: Icons.queue_music,
        tooltip: l10n.appTitle,
      ),
      _NavItem(
        index: 1,
        id: 'patcher',
        icon: Icons.build_outlined,
        tooltip: l10n.patcherTitle,
      ),
      _NavItem(
        index: 2,
        id: 'tools',
        icon: Icons.construction_outlined,
        tooltip: l10n.toolsTitle,
      ),
      _NavItem(
        index: 3,
        id: 'dreamcast',
        icon: Icons.sports_esports_outlined,
        tooltip: l10n.dreamcastTitle,
      ),
      _NavItem(
        index: 4,
        id: 'plugins',
        icon: Icons.extension_outlined,
        tooltip: l10n.navPlugins,
      ),
      _NavItem(
        index: 5,
        id: 'settings',
        icon: Icons.settings,
        tooltip: l10n.settingsScreen,
      ),
      _NavItem(
        index: 6,
        id: 'about',
        icon: Icons.info_outline,
        tooltip: l10n.aboutScreen,
      ),
      _NavItem(
        index: 7,
        id: 'theme',
        icon: Icons.palette,
        tooltip: l10n.themeScreen,
      ),
    ];

    // A skin may hide tabs; filter them out (order preserved).
    final hidden = theme.hiddenTabs.toSet();
    final items = all.where((i) => !hidden.contains(i.id)).toList();

    return Container(
      width: 64,
      color: theme.sidebarBg,
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Hexagon Logo Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.accent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.hexagon, color: theme.accent, size: 28),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = selectedIndex == item.index;
                final color = isSelected ? theme.accent : theme.textSecondary;
                return Tooltip(
                  message: item.tooltip,
                  child: InkWell(
                    onTap: () => onDestinationSelected(item.index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color:
                                isSelected ? theme.accent : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: theme.accent.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : [],
                      ),
                      child: _NavIcon(
                        item: item,
                        color: color,
                        iconDir: theme.iconDir,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders a sidebar icon: the skin's `icons/<id>.png` override when present,
/// else the built-in Material [Icon].
///
/// A custom icon is drawn at its natural colours (raw pixels); the built-in
/// icon is tinted with the theme's accent/muted [color].
class _NavIcon extends StatelessWidget {
  final _NavItem item;
  final Color color;
  final String? iconDir;

  const _NavIcon({
    required this.item,
    required this.color,
    required this.iconDir,
  });

  @override
  Widget build(BuildContext context) {
    final file = _iconFile();
    if (file != null) {
      return Image.file(
        file,
        width: 24,
        height: 24,
        fit: BoxFit.contain,
        // A broken icon must never blank the whole sidebar.
        errorBuilder: (_, __, ___) => Icon(item.icon, color: color, size: 24),
      );
    }
    return Icon(item.icon, color: color, size: 24);
  }

  File? _iconFile() {
    final dir = iconDir;
    if (dir == null || dir.isEmpty) return null;
    final file = File(p.join(dir, '${item.id}.png'));
    return file.existsSync() ? file : null;
  }
}
