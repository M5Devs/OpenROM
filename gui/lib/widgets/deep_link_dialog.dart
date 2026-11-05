// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'package:flutter/material.dart';
import 'package:openrom_core/openrom_core.dart';

import '../models/theme_config.dart';

/// Keys used by widget tests to drive the deep-link dialog.
abstract final class DeepLinkDialogKeys {
  static const install = Key('deeplink.install');
  static const cancel = Key('deeplink.cancel');
}

/// Asks the user to confirm an install triggered by an `openrom://` link.
///
/// Deep links are an untrusted input channel: anyone can craft
/// `openrom://install/<id>`. The dialog therefore shows exactly what will be
/// installed and who publishes it, and defaults to Cancel. The actual install
/// still goes through the SHA-256-verified download path, so a spoofed name
/// cannot smuggle different bytes.
Future<bool> showDeepLinkInstallDialog({
  required BuildContext context,
  required ThemeConfig theme,
  required StoreListing listing,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => AlertDialog(
      backgroundColor: theme.surface,
      title: Row(
        children: [
          Icon(Icons.link, color: theme.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Install plugin from link?',
              style: TextStyle(color: theme.textPrimary),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'An openrom:// link wants to install a plugin. Review it before '
              'continuing.',
              style: TextStyle(color: theme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 14),
            _row(theme, 'Plugin', listing.name),
            _row(theme, 'ID', listing.id),
            _row(theme, 'Version', listing.version),
            _row(theme, 'Publisher', listing.publisherName),
            _row(theme, 'Category', listing.category),
            if (listing.minCoreVersion != null &&
                listing.minCoreVersion!.isNotEmpty)
              _row(theme, 'Requires core', listing.minCoreVersion!),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.cardBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified_user_outlined,
                      size: 16, color: theme.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'The download is verified against the store\'s published '
                      'SHA-256 before installation.',
                      style:
                          TextStyle(color: theme.textSecondary, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: DeepLinkDialogKeys.cancel,
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          key: DeepLinkDialogKeys.install,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.accent,
            foregroundColor: Colors.black,
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          icon: const Icon(Icons.download, size: 18),
          label: const Text('Install'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// Shown when a link targets a plugin that is not in the catalogue.
Future<void> showDeepLinkNotFoundDialog({
  required BuildContext context,
  required ThemeConfig theme,
  required DeepLinkTarget target,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: theme.surface,
      title: Row(
        children: [
          const Icon(Icons.link_off, color: Colors.orangeAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Plugin not found',
                style: TextStyle(color: theme.textPrimary)),
          ),
        ],
      ),
      content: Text(
        'No plugin with the id "${target.id}" was found in the store '
        'catalogue.',
        style: TextStyle(color: theme.textSecondary, fontSize: 13),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.accent,
            foregroundColor: Colors.black,
          ),
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

Widget _row(ThemeConfig theme, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(label,
              style: TextStyle(color: theme.textSecondary, fontSize: 12)),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
