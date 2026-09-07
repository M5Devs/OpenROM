// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3 + Commons Clause

import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'errors.dart';

void showOpenROMError(
  BuildContext context,
  OpenROMError error, {
  String? details,
  VoidCallback? onAction,
}) {
  showDialog(
    context: context,
    builder: (ctx) => OpenROMErrorDialog(
      error: error,
      details: details,
      onAction: onAction,
    ),
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
      title: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                widget.error.icon,
                color: widget.error.color,
                size: 32,
              ),
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
          Positioned(
            top: 0,
            right: 0,
            child: Image.asset(
              'assets/icons/romeo_sad.png',
              width: 40,
              height: 40,
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                _getLocalizedMessage(l10n),
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.error.action,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              if (widget.details != null && widget.details!.trim().isNotEmpty) ...[
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
                        _isDetailsExpanded ? Icons.arrow_drop_down : Icons.arrow_right,
                        size: 20,
                        color: Colors.grey,
                      ),
                      Text(
                        l10n.errorDetailsLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
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
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        widget.details!.trim(),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ],
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
