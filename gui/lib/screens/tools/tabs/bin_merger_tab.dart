// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:io';
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

class BinMergerTab extends StatefulWidget {
  final ThemeConfig theme;

  const BinMergerTab({super.key, required this.theme});

  @override
  State<BinMergerTab> createState() => _BinMergerTabState();
}

class _BinMergerTabState extends State<BinMergerTab> {
  final ToolsService _toolsService = ToolsService();

  String _cuePath = '';
  String _outputDir = '';
  List<String> _detectedBinFiles = [];
  double _progress = 0.0;
  String? _successMessage;
  bool _isProcessing = false;
  bool _isDragging = false;

  void _selectCueFile(String path) {
    setState(() {
      _cuePath = path;
      _successMessage = null;
      _progress = 0.0;
      if (_outputDir.isEmpty && path.isNotEmpty) {
        _outputDir = p.dirname(path);
      }
      _parseCueAndDetectBins(path);
    });
  }

  void _parseCueAndDetectBins(String cueFilePath) {
    try {
      final file = File(cueFilePath);
      if (!file.existsSync()) return;

      final lines = file.readAsLinesSync();
      final cueDir = p.dirname(cueFilePath);
      final List<String> bins = [];

      final fileRegex = RegExp(
        r'FILE\s+["'
        "'"
        r']?([^"'
        "'"
        r']+)["'
        "'"
        r']?\s+BINARY',
        caseSensitive: false,
      );

      for (final line in lines) {
        final match = fileRegex.firstMatch(line.trim());
        if (match != null) {
          final relName = match.group(1);
          if (relName != null) {
            bins.add(p.join(cueDir, relName));
          }
        }
      }

      setState(() {
        _detectedBinFiles = bins;
      });
    } catch (_) {
      setState(() {
        _detectedBinFiles = [];
      });
    }
  }

  Future<void> _pickCueFile() async {
    final result = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['cue'],
    );
    if (result?.path != null) {
      _selectCueFile(result!.path!);
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

  Future<void> _mergeBins() async {
    if (_cuePath.isEmpty || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _progress = 0.0;
      _successMessage = null;
    });

    final l10n = AppLocalizations.of(context);

    try {
      final res = await _toolsService.mergeBins(
        cuePath: _cuePath,
        outputDir: _outputDir.isNotEmpty ? _outputDir : null,
        onProgress: (pct) {
          setState(() {
            _progress = pct;
          });
        },
      );

      setState(() {
        _successMessage = l10n.binMergerSuccess(p.basename(res.mergedBinPath));
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
        final cueFiles = detail.files
            .where((f) => p.extension(f.path).toLowerCase() == '.cue')
            .toList();
        if (cueFiles.isNotEmpty) {
          _selectCueFile(cueFiles.first.path);
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
                Icon(Icons.link, color: theme.accent, size: 28),
                const SizedBox(width: 10),
                Text(
                  l10n.binMergerTitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // CUE File Section
            Text(
              l10n.binMergerCueFile,
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
                    controller: TextEditingController(text: _cuePath),
                    decoration: InputDecoration(
                      hintText: '/path/to/game.cue (drag & drop supported)',
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
                  onPressed: _pickCueFile,
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_detectedBinFiles.isNotEmpty) ...[
              Text(
                l10n.binMergerDetected(_detectedBinFiles.length),
                style: TextStyle(
                  color: theme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              ...List.generate(_detectedBinFiles.length, (idx) {
                final trackName = p.basename(_detectedBinFiles[idx]);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 8),
                  child: Text(
                    'Track ${idx + 1}: $trackName',
                    style: TextStyle(color: theme.textSecondary, fontSize: 13),
                  ),
                );
              }),
              const SizedBox(height: 12),
            ],

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
                      text: _outputDir.isNotEmpty ? _outputDir : 'same as CUE',
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

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed:
                    (_cuePath.isNotEmpty && !_isProcessing) ? _mergeBins : null,
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
                        l10n.binMergerButton,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),

            if (_isProcessing) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: _progress / 100.0,
                backgroundColor: Colors.white10,
                color: theme.accent,
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${_progress.toStringAsFixed(0)}%',
                  style: TextStyle(color: theme.textSecondary, fontSize: 12),
                ),
              ),
            ],

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
