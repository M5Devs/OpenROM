// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../../../widgets/error_dialog.dart';
import '../../../models/errors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/theme_config.dart';
import '../../../services/core_bridge.dart';
import '../../../services/tools_service.dart';

class HeaderRemoverTab extends StatefulWidget {
  final ThemeConfig theme;

  const HeaderRemoverTab({super.key, required this.theme});

  @override
  State<HeaderRemoverTab> createState() => _HeaderRemoverTabState();
}

class _HeaderRemoverTabState extends State<HeaderRemoverTab> {
  final ToolsService _toolsService = ToolsService();

  String _romPath = '';
  HeaderInfo? _headerInfo;
  bool _backup = true;
  String? _successMessage;
  bool _isProcessing = false;
  bool _isDetecting = false;
  bool _isDragging = false;

  static const Set<String> _supportedExtensions = {
    '.nes',
    '.smc',
    '.sfc',
    '.fig',
    '.swc',
    '.gb',
    '.gbc',
    '.gba',
  };

  void _selectRomFile(String path) {
    setState(() {
      _romPath = path;
      _headerInfo = null;
      _successMessage = null;
    });
    _detectHeader(path);
  }

  Future<void> _detectHeader(String path) async {
    if (path.isEmpty) return;

    setState(() {
      _isDetecting = true;
    });

    try {
      final info = await _toolsService.detectHeader(path);
      if (mounted) {
        setState(() {
          _headerInfo = info;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _headerInfo = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDetecting = false;
        });
      }
    }
  }

  Future<void> _pickRomFile() async {
    final result = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: [
        'nes',
        'smc',
        'sfc',
        'fig',
        'swc',
        'gb',
        'gbc',
        'gba',
      ],
    );
    if (result?.path != null) {
      _selectRomFile(result!.path!);
    }
  }

  Future<void> _removeHeader() async {
    if (_romPath.isEmpty || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _successMessage = null;
    });

    final l10n = AppLocalizations.of(context);

    try {
      final cleanPath = await _toolsService.removeHeader(
        romPath: _romPath,
        backup: _backup,
      );

      setState(() {
        _successMessage = l10n.headerRemoverSuccess(p.basename(cleanPath));
      });
    } on OpenROMException catch (e) {
      if (mounted) {
        showOpenROMError(context, e.error, details: e.details);
      }
    } catch (e) {
      if (mounted) {
        showOpenROMError(
          context,
          OpenROMError.conversionFailed,
          details: e.toString(),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = widget.theme;

    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (detail) {
        setState(() => _isDragging = false);
        final romFiles = detail.files
            .where(
              (f) => _supportedExtensions.contains(
                p.extension(f.path).toLowerCase(),
              ),
            )
            .toList();
        if (romFiles.isNotEmpty) {
          _selectRomFile(romFiles.first.path);
        }
      },
      child: Container(
        color: _isDragging
            ? theme.accent.withValues(alpha: 0.1)
            : theme.background,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                Icon(Icons.content_cut, color: theme.accent, size: 28),
                const SizedBox(width: 10),
                Text(
                  l10n.headerRemoverTitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ROM File Section
            Text(
              l10n.patcherRomFile,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: theme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    readOnly: true,
                    controller: TextEditingController(text: _romPath),
                    decoration: InputDecoration(
                      hintText: '/path/to/game.smc (drag & drop supported)',
                      filled: true,
                      fillColor: theme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.folder_open, color: theme.accent),
                  onPressed: _pickRomFile,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Detection Result Section
            if (_isDetecting)
              const CircularProgressIndicator()
            else if (_headerInfo != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detection Result:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${l10n.headerRemoverSystem}: ${_headerInfo!.system}',
                      style: TextStyle(color: theme.textSecondary),
                    ),
                    Text(
                      _headerInfo!.hasHeader
                          ? 'Header: ✅ ${l10n.headerRemoverFound} (${_headerInfo!.headerSize} bytes)'
                          : 'Header: ❌ ${l10n.headerRemoverNotFound}',
                      style: TextStyle(
                        color: _headerInfo!.hasHeader
                            ? Colors.greenAccent
                            : theme.textSecondary,
                      ),
                    ),
                    Text(
                      '${l10n.headerRemoverConfidence}: ${_headerInfo!.confidence}',
                      style: TextStyle(color: theme.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else if (_romPath.isNotEmpty) ...[
              Text(
                l10n.headerRemoverNoHeader,
                style: TextStyle(color: theme.textSecondary),
              ),
              const SizedBox(height: 16),
            ],

            // Checkbox
            Row(
              children: [
                Checkbox(
                  value: _backup,
                  activeColor: theme.accent,
                  onChanged: (val) => setState(() => _backup = val ?? true),
                ),
                Text(
                  l10n.headerRemoverBackup,
                  style: TextStyle(color: theme.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: (_romPath.isNotEmpty && !_isProcessing)
                    ? _removeHeader
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.accent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : Text(
                        l10n.headerRemoverButton,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),

            if (_successMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Text(
                  '✅ $_successMessage',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
