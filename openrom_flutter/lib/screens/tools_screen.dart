// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3 + Commons Clause

import 'dart:io';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../core/error_dialog.dart';
import '../core/errors.dart';
import '../l10n/app_localizations.dart';
import '../models/theme_config.dart';
import '../services/compressor_service.dart';
import '../services/core_bridge.dart';
import '../services/m3u_service.dart';

class ToolsScreen extends StatefulWidget {
  final ThemeConfig theme;

  const ToolsScreen({
    super.key,
    required this.theme,
  });

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: widget.theme.background,
      body: Column(
        children: [
          // Sub-Tab Navigation Header
          Container(
            color: widget.theme.sidebarBg,
            child: TabBar(
              controller: _tabController,
              indicatorColor: widget.theme.accent,
              labelColor: widget.theme.accent,
              unselectedLabelColor: widget.theme.textSecondary,
              tabs: [
                Tab(
                  icon: const Icon(Icons.archive_outlined),
                  text: l10n.compressorTitle,
                ),
                Tab(
                  icon: const Icon(Icons.playlist_add_outlined),
                  text: l10n.m3uTitle,
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _CompressorTab(theme: widget.theme),
                _M3uTab(theme: widget.theme),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab 1: ROM Compressor ─────────────────────────────────────────────────────

class _CompressorQueueItem {
  final String filepath;
  String status; // "Queued", "Compressing", "Extracting", "Done", "Failed", "Skipped"
  double progress;
  String? error;

  _CompressorQueueItem({
    required this.filepath,
    this.status = 'Queued',
    this.progress = 0.0,
    this.error,
  });
}

class _CompressorTab extends StatefulWidget {
  final ThemeConfig theme;

  const _CompressorTab({required this.theme});

  @override
  State<_CompressorTab> createState() => _CompressorTabState();
}

class _CompressorTabState extends State<_CompressorTab> {
  final CompressorService _compressorService = CompressorService();
  final List<_CompressorQueueItem> _queue = [];

  String _format = 'ZIP'; // "ZIP" | "7Z" | "Extract"
  String _level = 'Normal'; // "Fast" | "Normal" | "Ultra"
  bool _deleteSource = false;
  bool _sameFolder = true;
  String _outputDir = '';
  bool _isProcessing = false;
  bool _isDragging = false;

  static const Set<String> _excludedExtensions = {
    '.chd', '.cso', '.rvz', '.7z', '.zip', '.gz', '.zst', '.csz', '.zso'
  };

  bool _isAlreadyCompressed(String filepath) {
    final ext = p.extension(filepath).toLowerCase();
    return _excludedExtensions.contains(ext);
  }

  void _addFiles(List<String> paths) {
    setState(() {
      for (final path in paths) {
        if (!_queue.any((item) => item.filepath == path)) {
          final isSkipped = (_format != 'Extract') && _isAlreadyCompressed(path);
          _queue.add(_CompressorQueueItem(
            filepath: path,
            status: isSkipped ? 'Skipped' : 'Queued',
            progress: isSkipped ? 100.0 : 0.0,
            error: isSkipped ? 'Skipped (already compressed)' : null,
          ));
        }
      }
    });
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null && result.paths.isNotEmpty) {
      final paths = result.paths.whereType<String>().toList();
      _addFiles(paths);
    }
  }

  Future<void> _pickFolder() async {
    final folderPath = await FilePicker.platform.getDirectoryPath();
    if (folderPath != null && folderPath.isNotEmpty) {
      final dir = Directory(folderPath);
      if (dir.existsSync()) {
        final List<String> filePaths = [];
        await for (final entity in dir.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            filePaths.add(entity.path);
          }
        }
        _addFiles(filePaths);
      }
    }
  }

  Future<void> _pickOutputDir() async {
    final folderPath = await FilePicker.platform.getDirectoryPath();
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
        showOpenROMError(context, OpenROMError.conversionFailed, details: e.toString());
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
        color: _isDragging ? theme.accent.withValues(alpha: 0.1) : theme.background,
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
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textSecondary),
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
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) {
                      setState(() {
                        _format = fmt;
                        for (final item in _queue) {
                          if (item.status == 'Skipped' || item.status == 'Queued') {
                            final isSkipped = (_format != 'Extract') && _isAlreadyCompressed(item.filepath);
                            item.status = isSkipped ? 'Skipped' : 'Queued';
                            item.progress = isSkipped ? 100.0 : 0.0;
                            item.error = isSkipped ? l10n.compressorSkipped : null;
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
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textSecondary),
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
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
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
                  onChanged: (val) => setState(() => _deleteSource = val ?? false),
                ),
                Text(l10n.compressorDeleteSource, style: TextStyle(color: theme.textPrimary)),
                const SizedBox(width: 20),
                Checkbox(
                  value: _sameFolder,
                  activeColor: theme.accent,
                  onChanged: (val) => setState(() => _sameFolder = val ?? true),
                ),
                Text(l10n.compressorSameFolder, style: TextStyle(color: theme.textPrimary)),
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                onPressed: (_queue.isNotEmpty && !_isProcessing) ? _startProcess : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.accent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isProcessing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : Text(actionText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),

            // Queue List Header & Items
            Row(
              children: [
                Text('Queue (${_queue.length})', style: TextStyle(fontWeight: FontWeight.bold, color: theme.textPrimary)),
                const Spacer(),
                if (_queue.isNotEmpty)
                  TextButton(
                    onPressed: _isProcessing ? null : () => setState(() => _queue.clear()),
                    child: Text(l10n.clearQueue, style: const TextStyle(color: Colors.redAccent)),
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

  Widget _buildQueueCard(_CompressorQueueItem item, AppLocalizations l10n, ThemeConfig theme) {
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
                  style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                item.status == 'Skipped' ? l10n.compressorSkipped : item.status,
                style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
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
            Text(item.error!, style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
          ],
        ],
      ),
    );
  }
}

// ── Tab 2: M3U Generator ──────────────────────────────────────────────────────

class _M3uTab extends StatefulWidget {
  final ThemeConfig theme;

  const _M3uTab({required this.theme});

  @override
  State<_M3uTab> createState() => _M3uTabState();
}

class _M3uTabState extends State<_M3uTab> {
  final M3UService _m3uService = M3UService();
  final List<String> _discFiles = [];

  String _outputDir = '';
  String _m3uFilename = '';
  String? _successMessage;
  bool _isGenerating = false;
  bool _isDragging = false;

  static const Set<String> _supportedExtensions = {
    '.chd', '.bin', '.cue', '.iso', '.gdi', '.img', '.cdi'
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
      final match = RegExp(r'(?:disc|disk|cd)[\s\-_]*(\d+)', caseSensitive: false).firstMatch(p.basename(filepath));
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
      final cleaned = first.replaceAll(
        RegExp(r'[\s\-_]*[\(\[\{]?(?:Disc|Disk|CD)[\s\-_]*\d+[\)\]\}]?', caseSensitive: false),
        '',
      ).trim();
      _m3uFilename = '${cleaned.isNotEmpty ? cleaned : first}.m3u';
      if (_outputDir.isEmpty) {
        _outputDir = p.dirname(_discFiles.first);
      }
    }
  }

  Future<void> _pickDiscFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['chd', 'bin', 'cue', 'iso', 'gdi', 'img', 'cdi'],
    );
    if (result != null && result.paths.isNotEmpty) {
      final paths = result.paths.whereType<String>().toList();
      _addDiscFiles(paths);
    }
  }

  Future<void> _pickOutputDir() async {
    final folderPath = await FilePicker.platform.getDirectoryPath();
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
        showOpenROMError(context, OpenROMError.conversionFailed, details: e.toString());
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
        color: _isDragging ? theme.accent.withValues(alpha: 0.1) : theme.background,
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
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textPrimary),
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
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) newIndex -= 1;
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
                                backgroundColor: theme.accent.withValues(alpha: 0.2),
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(color: theme.accent, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(
                                'Disc ${index + 1}: ${p.basename(filepath)}',
                                style: TextStyle(color: theme.textPrimary, fontSize: 14),
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
                                  const Icon(Icons.drag_handle, color: Colors.grey),
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
              style: TextStyle(fontWeight: FontWeight.bold, color: theme.textPrimary),
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                onPressed: (_discFiles.isNotEmpty && !_isGenerating) ? _generateM3u : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.accent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isGenerating
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : Text(l10n.m3uButton, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                  style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
