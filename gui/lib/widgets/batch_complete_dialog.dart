// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/batch_stats.dart';
import '../models/theme_config.dart';
import '../utils/open_folder.dart';
import 'romeo_mascot.dart';

/// Shows the "Batch Complete!" celebration dialog, featuring the animated
/// ROMéo success mascot and — when the batch shrank the data — a highlight card
/// with the bytes and percentage saved.
Future<void> showBatchCompleteDialog(
  BuildContext context, {
  required BatchStats stats,
  required ThemeConfig theme,
  String outputDir = '',
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => BatchCompleteDialog(
      stats: stats,
      theme: theme,
      outputDir: outputDir,
    ),
  );
}

class BatchCompleteDialog extends StatelessWidget {
  final BatchStats stats;
  final ThemeConfig theme;
  final String outputDir;

  const BatchCompleteDialog({
    super.key,
    required this.stats,
    required this.theme,
    this.outputDir = '',
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final jobs = stats.jobsCompleted;
    final saved = stats.hasSavings;

    return AlertDialog(
      backgroundColor: theme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const RomeoMascot(asset: RomeoAssets.success, size: 120),
          const SizedBox(height: 16),
          Text(
            l10n.batchTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.accent.withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                if (saved) ...[
                  Icon(Icons.savings_outlined, color: theme.accent, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    l10n.batchSaved(stats.bytesSavedReadable),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.accent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.batchSavedDetail(
                      stats.savedPercentageReadable,
                      jobs,
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: theme.textSecondary),
                  ),
                ] else ...[
                  Icon(Icons.check_circle_outline,
                      color: theme.accent, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    l10n.batchAllProcessed(jobs),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.textPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        if (outputDir.isNotEmpty)
          TextButton.icon(
            onPressed: () => openFolderInFileManager(outputDir),
            icon: const Icon(Icons.folder_open, size: 18),
            label: Text(l10n.openOutputFolder),
          ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.accent,
            foregroundColor: Colors.black,
          ),
          child: Text(l10n.batchAwesome),
        ),
      ],
    );
  }
}
