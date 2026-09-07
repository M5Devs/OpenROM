// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3 + Commons Clause

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../core/error_dialog.dart';
import '../core/errors.dart';
import '../l10n/app_localizations.dart';
import '../models/theme_config.dart';
import '../patcher/patcher.dart';
import '../patcher/patcher_factory.dart';
import '../services/core_bridge.dart';
import '../services/patcher_service.dart';

class PatcherScreen extends StatefulWidget {
  final ThemeConfig theme;
  final PatcherService? patcherService;

  const PatcherScreen({
    super.key,
    required this.theme,
    this.patcherService,
  });

  @override
  State<PatcherScreen> createState() => _PatcherScreenState();
}

class _PatcherScreenState extends State<PatcherScreen> {
  late final PatcherService _patcherService;

  String _romPath = '';
  String _patchPath = '';
  String _outputPath = '';

  bool _sameFolder = true;
  bool _ignoreChecksum = false;
  bool _isPatching = false;
  bool _isDragging = false;

  PatchReport? _report;

  @override
  void initState() {
    super.initState();
    _patcherService = widget.patcherService ?? PatcherService();
  }

  void _updateOutputPath() {
    if (_sameFolder && _romPath.isNotEmpty) {
      final dir = p.dirname(_romPath);
      final ext = p.extension(_romPath);
      final nameWithoutExt = p.basenameWithoutExtension(_romPath);
      setState(() {
        _outputPath = p.join(dir, '${nameWithoutExt}_patched$ext');
      });
    }
  }

  Future<void> _pickRomFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _romPath = result.files.single.path!;
        _report = null;
      });
      _updateOutputPath();
    }
  }

  Future<void> _pickPatchFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: PatcherFactory.supportedExtensions.toList(),
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _patchPath = result.files.single.path!;
        _report = null;
      });
    }
  }

  Future<void> _pickOutputFile() async {
    String? initialDir;
    String? initialName;
    if (_romPath.isNotEmpty) {
      initialDir = p.dirname(_romPath);
      final ext = p.extension(_romPath);
      final nameWithoutExt = p.basenameWithoutExtension(_romPath);
      initialName = '${nameWithoutExt}_patched$ext';
    }

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Select Output File',
      fileName: initialName ?? 'patched_game',
      initialDirectory: initialDir,
    );

    if (savePath != null && savePath.isNotEmpty) {
      setState(() {
        _outputPath = savePath;
        _report = null;
      });
    }
  }

  void _handleDroppedFiles(List<String> paths) {
    if (paths.isEmpty) return;

    String? newPatch;
    String? newRom;

    if (paths.length >= 2) {
      for (final path in paths) {
        if (PatcherFactory.isSupportedPatch(path)) {
          newPatch ??= path;
        } else {
          newRom ??= path;
        }
      }
    } else {
      final path = paths.first;
      if (PatcherFactory.isSupportedPatch(path)) {
        newPatch = path;
      } else {
        newRom = path;
      }
    }

    setState(() {
      _patchPath = newPatch ?? _patchPath;
      _romPath = newRom ?? _romPath;
      _report = null;
    });

    _updateOutputPath();
  }

  Future<void> _applyPatch() async {
    if (_romPath.isEmpty || _patchPath.isEmpty || _outputPath.isEmpty) return;

    setState(() {
      _isPatching = true;
      _report = null;
    });

    try {
      final report = await _patcherService.applyPatch(
        romPath: _romPath,
        patchPath: _patchPath,
        outputPath: _outputPath,
        ignoreChecksum: _ignoreChecksum,
      );

      if (mounted) {
        setState(() {
          _report = report;
          _isPatching = false;
        });
      }
    } on OpenROMException catch (e) {
      if (mounted) {
        setState(() => _isPatching = false);
        showOpenROMError(context, e.error, details: e.details);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPatching = false);
        showOpenROMError(context, OpenROMError.conversionFailed, details: e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = widget.theme;
    final formatBadge = PatcherFactory.formatName(_patchPath);
    final canApply = !_isPatching && _romPath.isNotEmpty && _patchPath.isNotEmpty && _outputPath.isNotEmpty;

    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (details) {
        setState(() => _isDragging = false);
        _handleDroppedFiles(details.files.map((f) => f.path).toList());
      },
      child: Stack(
        children: [
          Container(
            color: theme.background,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28.0),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          const Text(
                            '🩹',
                            style: TextStyle(fontSize: 28),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            l10n.patcherTitle,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: theme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ROM File Picker
                      _buildFileSection(
                        label: l10n.patcherRomFile,
                        path: _romPath,
                        onBrowse: _pickRomFile,
                        theme: theme,
                        browseTooltip: l10n.browse,
                      ),
                      const SizedBox(height: 20),

                      // Patch File Picker + Badge
                      _buildFileSection(
                        label: l10n.patcherPatchFile,
                        path: _patchPath,
                        onBrowse: _pickPatchFile,
                        theme: theme,
                        browseTooltip: l10n.browse,
                      ),
                      if (formatBadge != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.accent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                formatBadge,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'auto-detected',
                              style: TextStyle(
                                color: theme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 20),

                      // Output File Picker
                      _buildFileSection(
                        label: l10n.patcherOutputFile,
                        path: _outputPath,
                        onBrowse: _pickOutputFile,
                        theme: theme,
                        browseTooltip: l10n.browse,
                      ),
                      const SizedBox(height: 6),

                      // Same folder as ROM checkbox
                      CheckboxListTile(
                        value: _sameFolder,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: theme.accent,
                        title: Text(
                          l10n.patcherSameFolder,
                          style: TextStyle(color: theme.textPrimary, fontSize: 14),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _sameFolder = val ?? true;
                          });
                          _updateOutputPath();
                        },
                      ),
                      const SizedBox(height: 4),

                      // Ignore checksum errors checkbox
                      CheckboxListTile(
                        value: _ignoreChecksum,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: theme.accent,
                        title: Text(
                          l10n.patcherIgnoreChecksum,
                          style: TextStyle(color: theme.textPrimary, fontSize: 14),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _ignoreChecksum = val ?? false;
                          });
                        },
                      ),
                      const SizedBox(height: 24),

                      // Apply Patch Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.accent,
                            disabledBackgroundColor: theme.accent.withValues(alpha: 0.4),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(theme.borderRadius),
                            ),
                          ),
                          onPressed: canApply ? _applyPatch : null,
                          child: _isPatching
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  l10n.patcherApplyButton,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                      // Result Report Card
                      if (_report != null) ...[
                        const SizedBox(height: 28),
                        const Divider(color: Colors.white12),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.surface,
                            borderRadius: BorderRadius.circular(theme.borderRadius),
                            border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.greenAccent, size: 24),
                                  const SizedBox(width: 10),
                                  Text(
                                    l10n.patcherSuccess,
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${l10n.patcherFormat}: ${_report!.format.toUpperCase()}',
                                style: TextStyle(
                                  color: theme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              if (_report!.checks.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                ..._report!.checks.map((check) {
                                  final isPassed = check.outcome == CheckOutcome.passed;
                                  final outcomeText = isPassed
                                      ? l10n.patcherChecksumPassed
                                      : l10n.patcherChecksumSkipped;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isPassed ? Icons.check : Icons.remove,
                                          color: isPassed ? Colors.greenAccent : Colors.amberAccent,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${check.label} $outcomeText',
                                          style: TextStyle(
                                            color: theme.textSecondary,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Drag & drop highlight overlay
          if (_isDragging)
            Container(
              color: theme.background.withValues(alpha: 0.85),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.file_download, size: 64, color: theme.accent),
                    const SizedBox(height: 16),
                    Text(
                      l10n.patcherDropHint,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFileSection({
    required String label,
    required String path,
    required VoidCallback onBrowse,
    required ThemeConfig theme,
    required String browseTooltip,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(theme.borderRadius),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  path.isEmpty ? '...' : path,
                  style: TextStyle(
                    color: path.isEmpty ? theme.textSecondary : theme.textPrimary,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              style: IconButton.styleFrom(
                backgroundColor: theme.surface,
                foregroundColor: theme.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(theme.borderRadius),
                  side: const BorderSide(color: Colors.white12),
                ),
                padding: const EdgeInsets.all(12),
              ),
              onPressed: onBrowse,
              tooltip: browseTooltip,
              icon: const Icon(Icons.folder_open, size: 20),
            ),
          ],
        ),
      ],
    );
  }
}
