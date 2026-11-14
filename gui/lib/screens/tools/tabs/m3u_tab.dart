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
import '../../../services/m3u_service.dart';

class M3uTab extends StatefulWidget {
  final ThemeConfig theme;

  const M3uTab({super.key, required this.theme});

  @override
  State<M3uTab> createState() => _M3uTabState();
}

class _M3uTabState extends State<M3uTab> {
  final M3UService _m3uService = M3UService();
  final List<String> _discFiles = [];

  String _outputDir = '';
  String _m3uFilename = '';
  String? _successMessage;
  bool _isGenerating = false;
  bool _isDragging = false;

  static const Set<String> _supportedExtensions = {
    '.chd',
    '.bin',
    '.cue',
    '.iso',
    '.gdi',
    '.img',
    '.cdi',
  };

  void _addDiscFiles(List<String> paths) {
    setState(() {
      for (final path in paths) {
        final ext = p.extension(path).toLowerCase();
        if (_supportedExtensions.contains(ext) && !_discFiles.contains(path)) {
          _discFiles.add(path);
        }
      }

      _autoSortDiscs();
      _updateAutoFilename();
    });
  }

  void _autoSortDiscs() {
    int getDiscNumber(String filepath) {
      final match = RegExp(
        r'(?:disc|disk|cd)[\s\-_]*(\d+)',
        caseSensitive: false,
      ).firstMatch(p.basename(filepath));
      if (match != null) {
        return int.tryParse(match.group(1) ?? '') ?? 999;
      }
      return 999;
    }

    _discFiles.sort((a, b) => getDiscNumber(a).compareTo(getDiscNumber(b)));
  }

  void _updateAutoFilename() {
    if (_discFiles.isNotEmpty) {
      final first = p.basenameWithoutExtension(_discFiles.first);
      final cleaned = first
          .replaceAll(
            RegExp(
              r'[\s\-_]*[\(\[\{]?(?:Disc|Disk|CD)[\s\-_]*\d+[\)\]\}]?',
              caseSensitive: false,
            ),
            '',
          )
          .trim();
      _m3uFilename = '${cleaned.isNotEmpty ? cleaned : first}.m3u';
      if (_outputDir.isEmpty) {
        _outputDir = p.dirname(_discFiles.first);
      }
    }
  }

  Future<void> _pickDiscFiles() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['chd', 'bin', 'cue', 'iso', 'gdi', 'img', 'cdi'],
    );
    if (result.isNotEmpty) {
      final paths = result.map((f) => f.path).whereType<String>().toList();
      _addDiscFiles(paths);
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

  Future<void> _generateM3u() async {
    if (_discFiles.isEmpty || _isGenerating) return;

    setState(() {
      _isGenerating = true;
      _successMessage = null;
    });

    final l10n = AppLocalizations.of(context);

    try {
      final outputPath = p.join(_outputDir, _m3uFilename);
      final createdPath = await _m3uService.generateM3u(
        discFiles: _discFiles,
        outputDir: outputPath,
        relative: true,
      );

      setState(() {
        _successMessage = l10n.m3uSuccess(p.basename(createdPath));
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
          _isGenerating = false;
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
        final paths = detail.files.map((f) => f.path).toList();
        _addDiscFiles(paths);
      },
      child: Container(
        color: _isDragging
            ? theme.accent.withValues(alpha: 0.1)
            : theme.background,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Drop Hint
            Row(
              children: [
                Icon(Icons.playlist_add, color: theme.accent, size: 28),
                const SizedBox(width: 10),
                Text(
                  l10n.m3uTitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _pickDiscFiles,
                  icon: const Icon(Icons.disc_full),
                  label: Text(l10n.compressorAddFiles),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.surface,
                    foregroundColor: theme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Drop Hint text
            Text(
              '${l10n.m3uDropHint} (CHD, BIN, CUE, ISO, GDI, IMG, CDI)',
              style: TextStyle(color: theme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),

            // Reorderable Disc List
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: _discFiles.isEmpty
                    ? Center(
                        child: Text(
                          l10n.m3uDropHint,
                          style: TextStyle(color: theme.textSecondary),
                        ),
                      )
                    : ReorderableListView.builder(
                        itemCount: _discFiles.length,
                        // ignore: deprecated_member_use
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            final item = _discFiles.removeAt(oldIndex);
                            _discFiles.insert(newIndex, item);
                            _updateAutoFilename();
                          });
                        },
                        itemBuilder: (context, index) {
                          final filepath = _discFiles[index];
                          return Card(
                            key: ValueKey(filepath),
                            color: theme.sidebarBg,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: theme.accent.withValues(
                                  alpha: 0.2,
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: theme.accent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                'Disc ${index + 1}: ${p.basename(filepath)}',
                                style: TextStyle(
                                  color: theme.textPrimary,
                                  fontSize: 14,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    color: theme.textSecondary,
                                    onPressed: () {
                                      setState(() {
                                        _discFiles.removeAt(index);
                                        _updateAutoFilename();
                                      });
                                    },
                                  ),
                                  const Icon(
                                    Icons.drag_handle,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Output Settings
            Text(
              'Output: $_m3uFilename',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    readOnly: true,
                    controller: TextEditingController(text: _outputDir),
                    decoration: InputDecoration(
                      labelText: l10n.m3uOutputLabel,
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

            // Generate Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: (_discFiles.isNotEmpty && !_isGenerating)
                    ? _generateM3u
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.accent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : Text(
                        l10n.m3uButton,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),

            if (_successMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
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
