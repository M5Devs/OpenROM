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
import '../../../services/compressor_service.dart';
import '../../../services/core_bridge.dart';

class CompressorQueueItem {
  final String filepath;
  String
      status; // "Queued", "Compressing", "Extracting", "Done", "Failed", "Skipped"
  double progress;
  String? error;

  CompressorQueueItem({
    required this.filepath,
    this.status = 'Queued',
    this.progress = 0.0,
    this.error,
  });
}

class CompressorTab extends StatefulWidget {
  final ThemeConfig theme;

  const CompressorTab({super.key, required this.theme});

  @override
  State<CompressorTab> createState() => _CompressorTabState();
}

class _CompressorTabState extends State<CompressorTab> {
  final CompressorService _compressorService = CompressorService();
  final List<CompressorQueueItem> _queue = [];

  String _format = 'ZIP'; // "ZIP" | "7Z" | "Extract"
  String _level = 'Normal'; // "Fast" | "Normal" | "Ultra"
  bool _deleteSource = false;
  bool _sameFolder = true;
  String _outputDir = '';
  bool _isProcessing = false;
  bool _isDragging = false;

  static const Set<String> _excludedExtensions = {
    '.chd',
    '.cso',
    '.rvz',
    '.7z',
    '.zip',
    '.gz',
    '.zst',
    '.csz',
    '.zso',
  };

  bool _isAlreadyCompressed(String filepath) {
    final ext = p.extension(filepath).toLowerCase();
    return _excludedExtensions.contains(ext);
  }

  void _addFiles(List<String> paths) {
    setState(() {
      for (final path in paths) {
        if (!_queue.any((item) => item.filepath == path)) {
          final isSkipped =
              (_format != 'Extract') && _isAlreadyCompressed(path);
          _queue.add(
            CompressorQueueItem(
              filepath: path,
              status: isSkipped ? 'Skipped' : 'Queued',
              progress: isSkipped ? 100.0 : 0.0,
              error: isSkipped ? 'Skipped (already compressed)' : null,
            ),
          );
        }
      }
    });
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.pickFiles();
    if (result.isNotEmpty) {
      final paths = result.map((f) => f.path).whereType<String>().toList();
      _addFiles(paths);
    }
  }

  Future<void> _pickFolder() async {
    final folderPath = await FilePicker.getDirectoryPath();
    if (folderPath != null && folderPath.isNotEmpty) {
      final dir = Directory(folderPath);
      if (dir.existsSync()) {
        final List<String> filePaths = [];
        await for (final entity in dir.list(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is File) {
            filePaths.add(entity.path);
          }
        }
        _addFiles(filePaths);
      }
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

  Future<void> _startProcess() async {
    if (_queue.isEmpty || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    final l10n = AppLocalizations.of(context);

    try {
      for (final item in _queue) {
        if (_format != 'Extract' && _isAlreadyCompressed(item.filepath)) {
          setState(() {
            item.status = 'Skipped';
            item.progress = 100.0;
            item.error = l10n.compressorSkipped;
          });
          continue;
        }

        final targetDir = _sameFolder ? p.dirname(item.filepath) : _outputDir;

        if (_format == 'Extract') {
          setState(() {
            item.status = 'Extracting';
            item.progress = 0.0;
          });

          await _compressorService.extractFiles(
            files: [item.filepath],
            deleteSource: _deleteSource,
            outputDir: targetDir.isNotEmpty ? targetDir : null,
            onProgress: (pct) {
              setState(() {
                item.progress = pct;
              });
            },
            onDone: (success, err) {
              setState(() {
                item.status = success ? 'Done' : 'Failed';
                item.progress = success ? 100.0 : item.progress;
                item.error = err;
              });
            },
          );
        } else {
          setState(() {
            item.status = 'Compressing';
            item.progress = 0.0;
          });

          await _compressorService.compressFiles(
            files: [item.filepath],
            format: _format.toLowerCase(),
            level: _level.toLowerCase(),
            deleteSource: _deleteSource,
            outputDir: targetDir.isNotEmpty ? targetDir : null,
            onProgress: (pct) {
              setState(() {
                item.progress = pct;
              });
            },
            onDone: (success, err) {
              setState(() {
                item.status = success ? 'Done' : 'Failed';
                item.progress = success ? 100.0 : item.progress;
                item.error = err;
              });
            },
          );
        }
      }
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

    final actionText = _format == 'Extract'
        ? 'Extract (${_queue.length} Files)'
        : l10n.compressorButton(_queue.length);

    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (detail) {
        setState(() => _isDragging = false);
        final paths = detail.files.map((f) => f.path).toList();
        _addFiles(paths);
      },
      child: Container(
        color: _isDragging
            ? theme.accent.withValues(alpha: 0.1)
            : theme.background,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Add Buttons
            Row(
              children: [
                Icon(Icons.archive, color: theme.accent, size: 28),
                const SizedBox(width: 10),
                Text(
                  l10n.compressorTitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _pickFiles,
                  icon: const Icon(Icons.note_add_outlined),
                  label: Text(l10n.compressorAddFiles),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.surface,
                    foregroundColor: theme.textPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _pickFolder,
                  icon: const Icon(Icons.create_new_folder),
                  label: Text(l10n.compressorAddFolder),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.surface,
                    foregroundColor: theme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Format Selection Row
            Text(
              l10n.compressorOutputFormat,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: theme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: ['ZIP', '7Z', 'Extract'].map((fmt) {
                final selected = _format == fmt;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    label: Text(fmt),
                    selected: selected,
                    selectedColor: theme.accent,
                    backgroundColor: theme.surface,
                    labelStyle: TextStyle(
                      color: selected ? Colors.black : theme.textPrimary,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) {
                      setState(() {
                        _format = fmt;
                        for (final item in _queue) {
                          if (item.status == 'Skipped' ||
                              item.status == 'Queued') {
                            final isSkipped = (_format != 'Extract') &&
                                _isAlreadyCompressed(item.filepath);
                            item.status = isSkipped ? 'Skipped' : 'Queued';
                            item.progress = isSkipped ? 100.0 : 0.0;
                            item.error =
                                isSkipped ? l10n.compressorSkipped : null;
                          }
                        }
                      });
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Compression Level (7Z Only)
            if (_format == '7Z') ...[
              Text(
                l10n.compressorLevel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  MapEntry('Fast', l10n.compressorLevelFast),
                  MapEntry('Normal', l10n.compressorLevelNormal),
                  MapEntry('Ultra', l10n.compressorLevelUltra),
                ].map((entry) {
                  final key = entry.key;
                  final label = entry.value;
                  final selected = _level == key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: selected,
                      selectedColor: theme.accent,
                      backgroundColor: theme.surface,
                      labelStyle: TextStyle(
                        color: selected ? Colors.black : theme.textPrimary,
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) => setState(() => _level = key),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Checkboxes & Output folder
            Row(
              children: [
                Checkbox(
                  value: _deleteSource,
                  activeColor: theme.accent,
                  onChanged: (val) =>
                      setState(() => _deleteSource = val ?? false),
                ),
                Text(
                  l10n.compressorDeleteSource,
                  style: TextStyle(color: theme.textPrimary),
                ),
                const SizedBox(width: 20),
                Checkbox(
                  value: _sameFolder,
                  activeColor: theme.accent,
                  onChanged: (val) => setState(() => _sameFolder = val ?? true),
                ),
                Text(
                  l10n.compressorSameFolder,
                  style: TextStyle(color: theme.textPrimary),
                ),
              ],
            ),

            if (!_sameFolder) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      readOnly: true,
                      controller: TextEditingController(text: _outputDir),
                      decoration: InputDecoration(
                        hintText: l10n.m3uOutputLabel,
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
            ],
            const SizedBox(height: 16),

            // Main Action Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: (_queue.isNotEmpty && !_isProcessing)
                    ? _startProcess
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
                        actionText,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Queue List Header & Items
            Row(
              children: [
                Text(
                  'Queue (${_queue.length})',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                  ),
                ),
                const Spacer(),
                if (_queue.isNotEmpty)
                  TextButton(
                    onPressed: _isProcessing
                        ? null
                        : () => setState(() => _queue.clear()),
                    child: Text(
                      l10n.clearQueue,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
              ],
            ),
            const Divider(),
            Expanded(
              child: _queue.isEmpty
                  ? Center(
                      child: Text(
                        'Drag & Drop files here or click Add Files',
                        style: TextStyle(color: theme.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _queue.length,
                      itemBuilder: (context, index) {
                        final item = _queue[index];
                        return _buildQueueCard(item, l10n, theme);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueCard(
    CompressorQueueItem item,
    AppLocalizations l10n,
    ThemeConfig theme,
  ) {
    IconData statusIcon = Icons.hourglass_empty;
    Color statusColor = theme.textSecondary;

    if (item.status == 'Done') {
      statusIcon = Icons.check_circle;
      statusColor = Colors.green;
    } else if (item.status == 'Skipped') {
      statusIcon = Icons.remove_circle_outline;
      statusColor = Colors.orange;
    } else if (item.status == 'Failed') {
      statusIcon = Icons.error;
      statusColor = Colors.red;
    } else if (item.status == 'Compressing' || item.status == 'Extracting') {
      statusIcon = Icons.sync;
      statusColor = theme.accent;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  p.basename(item.filepath),
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                item.status == 'Skipped' ? l10n.compressorSkipped : item.status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!_isProcessing)
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: theme.textSecondary,
                  onPressed: () => setState(() => _queue.remove(item)),
                ),
            ],
          ),
          if (item.status == 'Compressing' || item.status == 'Extracting') ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: item.progress / 100.0,
              backgroundColor: Colors.white10,
              color: theme.accent,
            ),
          ],
          if (item.error != null && item.status == 'Failed') ...[
            const SizedBox(height: 4),
            Text(
              item.error!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}
