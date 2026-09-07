// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3 + Commons Clause

import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/theme_config.dart';

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
    final items = [
      {'icon': Icons.queue_music, 'tooltip': l10n.appTitle},
      {'icon': Icons.build_outlined, 'tooltip': l10n.patcherTitle},
      {'icon': Icons.construction_outlined, 'tooltip': l10n.toolsTitle},
      {'icon': Icons.settings, 'tooltip': l10n.settingsScreen},
      {'icon': Icons.info_outline, 'tooltip': l10n.aboutScreen},
      {'icon': Icons.palette, 'tooltip': l10n.themeScreen},
    ];

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
                final isSelected = selectedIndex == index;
                final color = isSelected ? theme.accent : theme.textSecondary;
                return Tooltip(
                  message: items[index]['tooltip'] as String,
                  child: InkWell(
                    onTap: () => onDestinationSelected(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: isSelected ? theme.accent : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: theme.accent.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                )
                              ]
                            : [],
                      ),
                      child: Icon(
                        items[index]['icon'] as IconData,
                        color: color,
                        size: 24,
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
