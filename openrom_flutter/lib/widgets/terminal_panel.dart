// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3 + Commons Clause

import 'package:flutter/material.dart';
import '../models/theme_config.dart';

class TerminalPanel extends StatelessWidget {
  final List<String> logs;
  final ThemeConfig theme;
  final VoidCallback onClose;
  final VoidCallback onClear;

  const TerminalPanel({
    super.key,
    required this.logs,
    required this.theme,
    required this.onClose,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: theme.terminalBg,
        border: Border(
          top: BorderSide(color: theme.accent.withOpacity(0.5), width: 1.5),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.black.withOpacity(0.3),
            child: Row(
              children: [
                Icon(Icons.terminal, color: theme.terminalText, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Execution Logs',
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.clear_all, size: 18),
                  color: theme.textSecondary,
                  onPressed: onClear,
                  tooltip: 'Clear Output',
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                  color: theme.textSecondary,
                  onPressed: onClose,
                  tooltip: 'Collapse',
                ),
              ],
            ),
          ),
          // Output lines
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final line = logs[index];
                return SelectableText(
                  line,
                  style: TextStyle(
                    fontFamily: 'Courier',
                    color: theme.terminalText,
                    fontSize: 12,
                    height: 1.4,
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
