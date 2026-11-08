// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/theme_config.dart';
import 'romeo_mascot.dart';

class TerminalPanel extends StatelessWidget {
  final List<String> logs;
  final ThemeConfig theme;
  final bool isConverting;
  final VoidCallback onClose;
  final VoidCallback onClear;

  const TerminalPanel({
    super.key,
    required this.logs,
    required this.theme,
    this.isConverting = false,
    required this.onClose,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: theme.terminalBg,
        border: Border(
          top: BorderSide(
            color: theme.accent.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.black.withValues(alpha: 0.3),
            child: Row(
              children: [
                Icon(Icons.terminal, color: theme.terminalText, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Execution Logs',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.clear_all, size: 18),
                  color: Colors.white70,
                  onPressed: onClear,
                  tooltip: l10n.clearQueue,
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                  color: Colors.white70,
                  onPressed: onClose,
                  tooltip: l10n.closeButton,
                ),
              ],
            ),
          ),
          // Live processing indicator: the animated working mascot sits above
          // the execution log while a batch is running.
          if (isConverting)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: Colors.black.withValues(alpha: 0.2),
              child: Column(
                children: [
                  const RomeoMascot(asset: RomeoAssets.working, size: 100),
                  const SizedBox(height: 8),
                  Text(
                    l10n.statusConverting,
                    style: TextStyle(
                      color: theme.terminalText,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
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
