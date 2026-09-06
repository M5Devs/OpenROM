// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3 + Commons Clause

import 'package:flutter/material.dart';
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
    final items = [
      {'icon': Icons.queue_music, 'tooltip': 'Queue (Home)'},
      {'icon': Icons.settings, 'tooltip': 'Settings'},
      {'icon': Icons.palette, 'tooltip': 'Themes'},
      {'icon': Icons.info_outline, 'tooltip': 'About'},
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
              color: theme.accent.withOpacity(0.2),
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
                                  color: theme.accent.withOpacity(0.4),
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
