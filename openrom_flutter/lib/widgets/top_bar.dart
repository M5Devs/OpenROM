// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3 + Commons Clause

import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/theme_config.dart';

class TopBar extends StatelessWidget {
  final ThemeConfig theme;
  final int fileCount;
  final bool isConverting;
  final VoidCallback onConvertPressed;
  final VoidCallback onAddFilesPressed;

  const TopBar({
    super.key,
    required this.theme,
    required this.fileCount,
    required this.isConverting,
    required this.onConvertPressed,
    required this.onAddFilesPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    String convertText;
    if (isConverting) {
      convertText = l10n.statusConverting.toUpperCase();
    } else if (fileCount > 0) {
      convertText = l10n.convertButtonWithCount(fileCount).toUpperCase();
    } else {
      convertText = l10n.convertButton.toUpperCase();
    }

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: theme.surface,
      child: Row(
        children: [
          Icon(Icons.hexagon_outlined, color: theme.accent, size: 28),
          const SizedBox(width: 10),
          Text(
            l10n.appTitle,
            style: TextStyle(
              fontFamily: theme.fontFamily,
              color: theme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: onAddFilesPressed,
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: Text(l10n.browse),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.surface,
              foregroundColor: theme.textPrimary,
              side: BorderSide(color: theme.accent.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(theme.borderRadius),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: (fileCount > 0 && !isConverting) ? onConvertPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.accent,
              foregroundColor: Colors.white,
              elevation: isConverting ? 0 : 6,
              shadowColor: theme.accent.withValues(alpha: 0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(theme.borderRadius),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              convertText,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
