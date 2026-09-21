// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3 + Commons Clause

import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/error_dialog.dart';
import '../core/errors.dart';
import '../l10n/app_localizations.dart';
import '../models/theme_config.dart';
import '../services/core_bridge.dart';
import '../services/patcher_service.dart';

class DreamcastScreen extends StatefulWidget {
  final ThemeConfig theme;
  const DreamcastScreen({super.key, required this.theme});

  @override
  State<DreamcastScreen> createState() => _DreamcastScreenState();
}

class _DreamcastScreenState extends State<DreamcastScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
          Container(
            color: widget.theme.sidebarBg,
            child: TabBar(
              controller: _tabController,
              indicatorColor: widget.theme.accent,
              labelColor: widget.theme.accent,
              unselectedLabelColor: widget.theme.textSecondary,
              tabs: [
                Tab(
                  icon: const Icon(Icons.healing_outlined),
                  text: l10n.dreamcastDcpTab,
                ),
                Tab(
                  icon: const Icon(Icons.memory_outlined),
                  text: l10n.dreamcastIpbinTab,
                ),
                Tab(
                  icon: const Icon(Icons.disc_full_outlined),
                  text: l10n.dreamcastGdiTab,
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _DcpApplyTab(theme: widget.theme),
                _IpBinEditorTab(theme: widget.theme),
                _GdiInfoTab(theme: widget.theme),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab 1: Apply DCP Patch ────────────────────────────────────────────────────

class _DcpApplyTab extends StatefulWidget {
  final ThemeConfig theme;
  const _DcpApplyTab({required this.theme});

  @override
  State<_DcpApplyTab> createState() => _DcpApplyTabState();
}

class _DcpApplyTabState extends State<_DcpApplyTab> {
  final PatcherService _patcherService = PatcherService();

  String _discDir = '';
  String _dcpPath = '';
  String _outputDir = '';
  bool _sameFolder = true;
  bool _ignoreChecksum = false;
  bool _isApplying = false;

  int? _filesPatchedCount;
  bool? _ipbinReplaced;

  Future<void> _pickDiscDir() async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path != null && path.isNotEmpty) {
      setState(() {
        _discDir = path;
        if (_sameFolder) {
          _outputDir = path;
        }
      });
    }
  }

  Future<void> _pickDcpFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['dcp'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _dcpPath = result.files.single.path!;
      });
    }
  }

  Future<void> _pickOutputDir() async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path != null && path.isNotEmpty) {
      setState(() {
        _outputDir = path;
      });
    }
  }

  Future<void> _applyPatch() async {
    if (_dcpPath.isEmpty || _discDir.isEmpty || _isApplying) return;

    setState(() {
      _isApplying = true;
      _filesPatchedCount = null;
      _ipbinReplaced = null;
    });

    final l10n = AppLocalizations.of(context);

    try {
      final targetOutput = _sameFolder ? _discDir : _outputDir;
      final result = await _patcherService.applyDcpPatch(
        dcpPath: _dcpPath,
        discDir: _discDir,
        outputDir: targetOutput.isNotEmpty ? targetOutput : _discDir,
        ignoreChecksum: _ignoreChecksum,
      );

      if (mounted) {
        setState(() {
          _filesPatchedCount = result.filesPatched;
          _ipbinReplaced = result.ipbinReplaced;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.dreamcastApplySuccess),
            backgroundColor: widget.theme.accent,
          ),
        );
      }
    } on OpenROMException catch (e) {
      if (mounted) {
        showOpenROMError(context, e.error, details: e.details);
      }
    } catch (e) {
      if (mounted) {
        showOpenROMError(context, OpenROMError.conversionFailed,
            details: e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isApplying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = widget.theme;

    final canApply =
        !_isApplying && _dcpPath.isNotEmpty && _discDir.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Disc Directory Picker
              Text(
                l10n.dreamcastDiscDir,
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.surface,
                        borderRadius: BorderRadius.circular(theme.borderRadius),
                        border: Border.all(color: theme.border),
                      ),
                      child: Text(
                        _discDir.isEmpty ? '...' : _discDir,
                        style: TextStyle(
                          color: _discDir.isEmpty
                              ? theme.textSecondary
                              : theme.textPrimary,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: theme.surface,
                      foregroundColor: theme.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(theme.borderRadius),
                        side: BorderSide(color: theme.border),
                      ),
                      padding: const EdgeInsets.all(12),
                    ),
                    onPressed: _pickDiscDir,
                    tooltip: l10n.dreamcastBrowse,
                    icon: const Icon(Icons.folder_open, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // DCP Patch File Picker
              Text(
                l10n.dreamcastDcpFile,
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.surface,
                        borderRadius: BorderRadius.circular(theme.borderRadius),
                        border: Border.all(color: theme.border),
                      ),
                      child: Text(
                        _dcpPath.isEmpty ? '...' : _dcpPath,
                        style: TextStyle(
                          color: _dcpPath.isEmpty
                              ? theme.textSecondary
                              : theme.textPrimary,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: theme.surface,
                      foregroundColor: theme.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(theme.borderRadius),
                        side: BorderSide(color: theme.border),
                      ),
                      padding: const EdgeInsets.all(12),
                    ),
                    onPressed: _pickDcpFile,
                    tooltip: l10n.dreamcastBrowse,
                    icon: const Icon(Icons.folder_open, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Output Directory Picker
              if (!_sameFolder) ...[
                Text(
                  l10n.dreamcastOutputDir,
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: theme.surface,
                          borderRadius:
                              BorderRadius.circular(theme.borderRadius),
                          border: Border.all(color: theme.border),
                        ),
                        child: Text(
                          _outputDir.isEmpty ? '...' : _outputDir,
                          style: TextStyle(
                            color: _outputDir.isEmpty
                                ? theme.textSecondary
                                : theme.textPrimary,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: theme.surface,
                        foregroundColor: theme.textPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(theme.borderRadius),
                          side: BorderSide(color: theme.border),
                        ),
                        padding: const EdgeInsets.all(12),
                      ),
                      onPressed: _pickOutputDir,
                      tooltip: l10n.dreamcastBrowse,
                      icon: const Icon(Icons.folder_open, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Same folder as source Checkbox
              CheckboxListTile(
                value: _sameFolder,
                contentPadding: EdgeInsets.zero,
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: theme.accent,
                title: Text(
                  l10n.dreamcastSameFolder,
                  style: TextStyle(color: theme.textPrimary, fontSize: 14),
                ),
                onChanged: (val) {
                  setState(() {
                    _sameFolder = val ?? true;
                    if (_sameFolder) {
                      _outputDir = _discDir;
                    }
                  });
                },
              ),
              const SizedBox(height: 4),

              // Ignore Checksum Checkbox
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

              // Apply Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.accent,
                    disabledBackgroundColor: theme.accent.withValues(alpha: 0.4),
                    foregroundColor: theme.textPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(theme.borderRadius),
                    ),
                  ),
                  onPressed: canApply ? _applyPatch : null,
                  child: _isApplying
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: theme.textPrimary,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          l10n.dreamcastApplyButton,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              if (_isApplying) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(color: theme.accent),
              ],

              // Result Row: files patched count + IP.BIN replaced bool
              if (_filesPatchedCount != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(theme.borderRadius),
                    border: Border.all(color: theme.accent),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: theme.accent, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Files patched: $_filesPatchedCount  |  IP.BIN replaced: ${_ipbinReplaced == true ? "Yes" : "No"}',
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tab 2: IP.BIN Editor ──────────────────────────────────────────────────────

class _IpBinEditorTab extends StatefulWidget {
  final ThemeConfig theme;
  const _IpBinEditorTab({required this.theme});

  @override
  State<_IpBinEditorTab> createState() => _IpBinEditorTabState();
}

class _IpBinEditorTabState extends State<_IpBinEditorTab> {
  String _ipbinPath = '';
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isLoaded = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _productNumberController =
      TextEditingController();
  final TextEditingController _versionController = TextEditingController();
  final TextEditingController _releaseDateController = TextEditingController();

  bool _japan = false;
  bool _usa = false;
  bool _europe = false;
  bool _vga = false;

  @override
  void dispose() {
    _titleController.dispose();
    _productNumberController.dispose();
    _versionController.dispose();
    _releaseDateController.dispose();
    super.dispose();
  }

  Future<void> _pickIpBinFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['bin', 'gdi'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _ipbinPath = result.files.single.path!;
        _isLoaded = false;
      });
    }
  }

  Future<void> _loadIpBin() async {
    if (_ipbinPath.isEmpty || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final res = await CoreBridge.runCore(['--read-ipbin', _ipbinPath, '--json']);

      if (res.exitCode == 0) {
        final lines = LineSplitter.split(res.stdout.toString())
            .where((l) => l.trim().isNotEmpty)
            .toList();

        Map<String, dynamic>? jsonMap;
        for (final line in lines.reversed) {
          try {
            final decoded = jsonDecode(line);
            if (decoded is Map<String, dynamic>) {
              jsonMap = decoded;
              break;
            }
          } catch (_) {}
        }

        if (jsonMap != null) {
          final fields = (jsonMap['fields'] as Map<String, dynamic>?) ?? jsonMap;
          final pName1 = (fields['product_name'] ?? '').toString();
          final pName2 = (fields['product_name_2'] ?? '').toString();
          final fullTitle = '$pName1 $pName2'.trim();

          final regions = (fields['regions'] as List?)?.map((e) => e.toString()).toList() ?? [];
          final peripheralsStr = (fields['peripherals'] ?? '').toString().trim();
          int peripFlags = 0;
          try {
            peripFlags = int.parse(peripheralsStr, radix: 16);
          } catch (_) {}

          setState(() {
            _titleController.text = fullTitle;
            _productNumberController.text = (fields['product_number'] ?? '').toString();
            _versionController.text = (fields['product_version'] ?? '').toString();
            _releaseDateController.text = (fields['release_date'] ?? '').toString();

            _japan = regions.contains('Japan');
            _usa = regions.contains('USA');
            _europe = regions.contains('Europe');
            _vga = (peripFlags & (1 << 4)) != 0;

            _isLoaded = true;
          });
        }
      } else {
        if (mounted) {
          showOpenROMError(
            context,
            OpenROMError.conversionFailed,
            details: res.stderr.toString().trim(),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showOpenROMError(context, OpenROMError.conversionFailed,
            details: e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveIpBin() async {
    if (_ipbinPath.isEmpty || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    final l10n = AppLocalizations.of(context);

    try {
      String regionCode = '';
      if (_japan) regionCode += 'J';
      if (_usa) regionCode += 'U';
      if (_europe) regionCode += 'E';

      final args = ['--write-ipbin', _ipbinPath];
      if (_titleController.text.isNotEmpty) {
        args.addAll(['--set-title', _titleController.text]);
      }
      if (regionCode.isNotEmpty) {
        args.addAll(['--set-region', regionCode]);
      }
      if (_vga) {
        args.add('--set-vga');
      }

      final res = await CoreBridge.runCore(args);

      if (res.exitCode == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.dreamcastIpbinSaveSuccess),
              backgroundColor: widget.theme.accent,
            ),
          );
        }
      } else {
        if (mounted) {
          showOpenROMError(
            context,
            OpenROMError.conversionFailed,
            details: res.stderr.toString().trim(),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showOpenROMError(context, OpenROMError.conversionFailed,
            details: e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = widget.theme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // IP.BIN File Selection Row
              Text(
                l10n.dreamcastIpbinFile,
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.surface,
                        borderRadius: BorderRadius.circular(theme.borderRadius),
                        border: Border.all(color: theme.border),
                      ),
                      child: Text(
                        _ipbinPath.isEmpty ? '...' : _ipbinPath,
                        style: TextStyle(
                          color: _ipbinPath.isEmpty
                              ? theme.textSecondary
                              : theme.textPrimary,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: theme.surface,
                      foregroundColor: theme.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(theme.borderRadius),
                        side: BorderSide(color: theme.border),
                      ),
                      padding: const EdgeInsets.all(12),
                    ),
                    onPressed: _pickIpBinFile,
                    tooltip: l10n.dreamcastBrowse,
                    icon: const Icon(Icons.folder_open, size: 20),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.accent,
                      foregroundColor: theme.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(theme.borderRadius),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                    ),
                    onPressed: (_ipbinPath.isNotEmpty && !_isLoading)
                        ? _loadIpBin
                        : null,
                    child: _isLoading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: theme.textPrimary,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(l10n.dreamcastIpbinLoad,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (_isLoaded) ...[
                // Editable Game Title
                Text(
                  l10n.dreamcastIpbinTitle,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  maxLength: 32,
                  style: TextStyle(color: theme.textPrimary),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: theme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(theme.borderRadius),
                      borderSide: BorderSide(color: theme.border),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Read-only Product Number, Version, Release Date
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.dreamcastIpbinProductNumber,
                            style: TextStyle(
                              color: theme.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _productNumberController,
                            readOnly: true,
                            style: TextStyle(color: theme.textSecondary),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: theme.surface,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(theme.borderRadius),
                                borderSide: BorderSide(color: theme.border),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.dreamcastIpbinVersion,
                            style: TextStyle(
                              color: theme.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _versionController,
                            readOnly: true,
                            style: TextStyle(color: theme.textSecondary),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: theme.surface,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(theme.borderRadius),
                                borderSide: BorderSide(color: theme.border),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.dreamcastIpbinDate,
                            style: TextStyle(
                              color: theme.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _releaseDateController,
                            readOnly: true,
                            style: TextStyle(color: theme.textSecondary),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: theme.surface,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(theme.borderRadius),
                                borderSide: BorderSide(color: theme.border),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Region Selection
                Text(
                  l10n.dreamcastIpbinRegion,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: _japan,
                  title: Text(l10n.dreamcastIpbinRegionJapan,
                      style: TextStyle(color: theme.textPrimary)),
                  activeColor: theme.accent,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (v) => setState(() => _japan = v ?? false),
                ),
                CheckboxListTile(
                  value: _usa,
                  title: Text(l10n.dreamcastIpbinRegionUSA,
                      style: TextStyle(color: theme.textPrimary)),
                  activeColor: theme.accent,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (v) => setState(() => _usa = v ?? false),
                ),
                CheckboxListTile(
                  value: _europe,
                  title: Text(l10n.dreamcastIpbinRegionEurope,
                      style: TextStyle(color: theme.textPrimary)),
                  activeColor: theme.accent,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (v) => setState(() => _europe = v ?? false),
                ),
                const SizedBox(height: 12),

                // VGA Switch
                SwitchListTile(
                  value: _vga,
                  title: Text(l10n.dreamcastIpbinVga,
                      style: TextStyle(
                          color: theme.textPrimary,
                          fontWeight: FontWeight.bold)),
                  activeThumbColor: theme.accent,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setState(() => _vga = v),
                ),
                const SizedBox(height: 24),

                // Save Changes Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.accent,
                      foregroundColor: theme.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(theme.borderRadius),
                      ),
                    ),
                    onPressed: !_isSaving ? _saveIpBin : null,
                    child: _isSaving
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: theme.textPrimary,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            l10n.dreamcastIpbinSave,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tab 3: GDI Info ───────────────────────────────────────────────────────────

class _GdiInfoTab extends StatefulWidget {
  final ThemeConfig theme;
  const _GdiInfoTab({required this.theme});

  @override
  State<_GdiInfoTab> createState() => _GdiInfoTabState();
}

class _GdiInfoTabState extends State<_GdiInfoTab> {
  String _gdiPath = '';
  bool _isLoading = false;
  List<Map<String, dynamic>> _tracks = [];

  Future<void> _pickGdiFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['gdi'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _gdiPath = result.files.single.path!;
        _tracks.clear();
      });
    }
  }

  Future<void> _loadGdi() async {
    if (_gdiPath.isEmpty || _isLoading) return;

    setState(() {
      _isLoading = true;
      _tracks.clear();
    });

    try {
      final res = await CoreBridge.runCore(['--read-gdi', _gdiPath]);

      if (res.exitCode == 0) {
        final lines = LineSplitter.split(res.stdout.toString())
            .where((l) => l.trim().isNotEmpty)
            .toList();

        List<dynamic>? jsonList;
        for (final line in lines.reversed) {
          try {
            final decoded = jsonDecode(line);
            if (decoded is List) {
              jsonList = decoded;
              break;
            }
          } catch (_) {}
        }

        if (jsonList != null) {
          setState(() {
            _tracks = jsonList!.cast<Map<String, dynamic>>();
          });
        }
      } else {
        if (mounted) {
          showOpenROMError(
            context,
            OpenROMError.conversionFailed,
            details: res.stderr.toString().trim(),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showOpenROMError(context, OpenROMError.conversionFailed,
            details: e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = widget.theme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // GDI File Selection Row
              Text(
                l10n.dreamcastGdiFile,
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.surface,
                        borderRadius: BorderRadius.circular(theme.borderRadius),
                        border: Border.all(color: theme.border),
                      ),
                      child: Text(
                        _gdiPath.isEmpty ? '...' : _gdiPath,
                        style: TextStyle(
                          color: _gdiPath.isEmpty
                              ? theme.textSecondary
                              : theme.textPrimary,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: theme.surface,
                      foregroundColor: theme.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(theme.borderRadius),
                        side: BorderSide(color: theme.border),
                      ),
                      padding: const EdgeInsets.all(12),
                    ),
                    onPressed: _pickGdiFile,
                    tooltip: l10n.dreamcastBrowse,
                    icon: const Icon(Icons.folder_open, size: 20),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.accent,
                      foregroundColor: theme.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(theme.borderRadius),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                    ),
                    onPressed: (_gdiPath.isNotEmpty && !_isLoading)
                        ? _loadGdi
                        : null,
                    child: _isLoading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: theme.textPrimary,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(l10n.dreamcastGdiLoad,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (_tracks.isNotEmpty) ...[
                Text(
                  l10n.dreamcastGdiTracks,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.surface,
                      borderRadius: BorderRadius.circular(theme.borderRadius),
                      border: Border.all(color: theme.border),
                    ),
                    child: DataTable(
                      columns: [
                        DataColumn(
                          label: Text(l10n.dreamcastGdiTrackNum,
                              style: TextStyle(
                                  color: theme.accent,
                                  fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          label: Text(l10n.dreamcastGdiTrackLba,
                              style: TextStyle(
                                  color: theme.accent,
                                  fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          label: Text(l10n.dreamcastGdiTrackType,
                              style: TextStyle(
                                  color: theme.accent,
                                  fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          label: Text(l10n.dreamcastGdiTrackSize,
                              style: TextStyle(
                                  color: theme.accent,
                                  fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          label: Text(l10n.dreamcastGdiTrackFile,
                              style: TextStyle(
                                  color: theme.accent,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                      rows: _tracks.map((t) {
                        final trackTypeStr = t['type'] == 'Audio'
                            ? l10n.dreamcastGdiAudio
                            : l10n.dreamcastGdiData;
                        return DataRow(
                          cells: [
                            DataCell(Text('${t['number']}',
                                style: TextStyle(color: theme.textPrimary))),
                            DataCell(Text('${t['lba']}',
                                style: TextStyle(color: theme.textPrimary))),
                            DataCell(Text(trackTypeStr,
                                style: TextStyle(color: theme.textPrimary))),
                            DataCell(Text('${t['sector_size']}',
                                style: TextStyle(color: theme.textPrimary))),
                            DataCell(Text('${t['filename']}',
                                style: TextStyle(color: theme.textPrimary))),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
