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

class CueGeneratorTab extends StatefulWidget {
  final ThemeConfig theme;

  const CueGeneratorTab({super.key, required this.theme});

  @override
  State<CueGeneratorTab> createState() => _CueGeneratorTabState();
}

class _CueGeneratorTabState extends State<CueGeneratorTab> {
  final ToolsService _toolsService = ToolsService();

  String _binPath = '';
  String _outputDir = '';
  String? _detectedMode;
  String? _successMessage;
  bool _isProcessing = false;
  bool _isDragging = false;

  void _selectBinFile(String path) {
    setState(() {
      _binPath = path;
      _successMessage = null;
      if (_outputDir.isEmpty && path.isNotEmpty) {
        _outputDir = p.dirname(path);
      }
    });
  }

  Future<void> _pickBinFile() async {
    final result = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['bin'],
    );
    if (result?.path != null) {
      _selectBinFile(result!.path!);
    }
  }

  Future<void> _pickOutputDir() async {
    final folderPath = await FilePicker.getDirectoryPath();
    if (folderPath != null && folderPath.isNotEmpty) {
      setState(() {
        _outputDir = folderPath;
      });
    }
  }

  Future<void> _generateCue() async {
    if (_binPath.isEmpty || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _successMessage = null;
    });

    final l10n = AppLocalizations.of(context);

    try {
      final res = await _toolsService.generateCue(
        binPath: _binPath,
        outputDir: _outputDir.isNotEmpty ? _outputDir : null,
      );

      setState(() {
        _detectedMode = res.detectedMode;
        _successMessage = l10n.cueGeneratorSuccess(p.basename(res.cuePath));
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
        final binFiles = detail.files
            .where((f) => p.extension(f.path).toLowerCase() == '.bin')
            .toList();
        if (binFiles.isNotEmpty) {
          _selectBinFile(binFiles.first.path);
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
                Icon(Icons.description, color: theme.accent, size: 28),
                const SizedBox(width: 10),
                Text(
                  l10n.cueGeneratorTitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // BIN File Section
            Text(
              l10n.cueGeneratorBinFile,
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
                    controller: TextEditingController(text: _binPath),
                    decoration: InputDecoration(
                      hintText: '/path/to/game.bin (drag & drop supported)',
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
                  onPressed: _pickBinFile,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Output Folder Section
            Text(
              l10n.m3uOutputLabel,
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
                    controller: TextEditingController(
                      text: _outputDir.isNotEmpty ? _outputDir : 'same as BIN',
                    ),
                    decoration: InputDecoration(
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
                  onPressed: _pickOutputDir,
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_detectedMode != null) ...[
              Text(
                '${l10n.cueGeneratorDetectedMode}: $_detectedMode',
                style: TextStyle(
                  color: theme.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: (_binPath.isNotEmpty && !_isProcessing)
                    ? _generateCue
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
                        l10n.cueGeneratorButton,
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
