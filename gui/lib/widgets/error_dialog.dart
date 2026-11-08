// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/errors.dart';
import 'romeo_mascot.dart';

void showOpenROMError(
  BuildContext context,
  OpenROMError error, {
  String? details,
  VoidCallback? onAction,
}) {
  showDialog(
    context: context,
    builder: (ctx) =>
        OpenROMErrorDialog(error: error, details: details, onAction: onAction),
  );
}

class OpenROMErrorDialog extends StatefulWidget {
  final OpenROMError error;
  final String? details;
  final VoidCallback? onAction;

  const OpenROMErrorDialog({
    super.key,
    required this.error,
    this.details,
    this.onAction,
  });

  @override
  State<OpenROMErrorDialog> createState() => _OpenROMErrorDialogState();
}

class _OpenROMErrorDialogState extends State<OpenROMErrorDialog> {
  bool _isDetailsExpanded = false;

  String _getLocalizedTitle(AppLocalizations? l10n) {
    return widget.error.title;
  }

  String _getLocalizedMessage(AppLocalizations? l10n) {
    if (l10n == null) return widget.error.message;
    switch (widget.error) {
      case OpenROMError.coreNotFound:
        return l10n.errorCoreNotFound;
      case OpenROMError.unsupportedFormat:
        return l10n.errorUnsupportedFormat;
      case OpenROMError.diskSpaceLow:
        return l10n.errorDiskSpace;
      case OpenROMError.toolFailed:
        return l10n.errorToolFailed;
      case OpenROMError.conversionFailed:
        return l10n.errorConversionFailed;
      case OpenROMError.fileNotFound:
        return l10n.errorFileNotFound;
      case OpenROMError.outputDirNotFound:
        return l10n.errorOutputDirNotFound;
      case OpenROMError.permissionDenied:
        return l10n.errorPermissionDenied;
      case OpenROMError.corruptedFile:
        return l10n.errorCorruptedFile;
      case OpenROMError.unknownError:
        return l10n.errorUnknown;
    }
  }

  String _getLocalizedActionLabel(AppLocalizations? l10n) {
    if (l10n == null) return widget.error.actionLabel;
    switch (widget.error) {
      case OpenROMError.diskSpaceLow:
        return l10n.retryButton;
      case OpenROMError.toolFailed:
      case OpenROMError.unknownError:
        return l10n.reportBugButton;
      case OpenROMError.fileNotFound:
      case OpenROMError.corruptedFile:
        return l10n.closeButton;
      default:
        return widget.error.actionLabel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const RomeoMascot(asset: RomeoAssets.error, size: 100),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _getLocalizedTitle(l10n),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 480,
          child: Builder(
            builder: (context) {
              final scheme = Theme.of(context).colorScheme;
              final isLight = Theme.of(context).brightness == Brightness.light;
              final mutedColor = isLight ? Colors.black54 : Colors.grey;
              final detailsBg = isLight
                  ? Colors.black.withValues(alpha: 0.05)
                  : Colors.black26;
              final detailsFg = isLight ? Colors.black87 : Colors.white70;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    _getLocalizedMessage(l10n),
                    style: TextStyle(
                      fontSize: 14,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.error.action,
                    style: TextStyle(fontSize: 12, color: mutedColor),
                  ),
                  if (widget.details != null &&
                      widget.details!.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isDetailsExpanded = !_isDetailsExpanded;
                        });
                      },
                      child: Row(
                        children: [
                          Icon(
                            _isDetailsExpanded
                                ? Icons.arrow_drop_down
                                : Icons.arrow_right,
                            size: 20,
                            color: mutedColor,
                          ),
                          Text(
                            l10n.errorDetailsLabel,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: mutedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isDetailsExpanded) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxHeight: 180),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: detailsBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: scheme.onSurface.withValues(alpha: 0.1),
                          ),
                        ),
                        child: SingleChildScrollView(
                          child: SelectableText(
                            widget.details!.trim(),
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: detailsFg,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.closeButton),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.error.color,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            Navigator.of(context).pop();
            if (widget.onAction != null) {
              widget.onAction!();
            }
          },
          child: Text(_getLocalizedActionLabel(l10n)),
        ),
      ],
    );
  }
}
