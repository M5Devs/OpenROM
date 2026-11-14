// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openrom_core/openrom_core.dart'
    show HasheousClient, HasheousLookupResult, OnlinePrefs;
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../widgets/error_dialog.dart';
import '../../../widgets/hasheous_result_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/theme_config.dart';
import '../../../services/core_bridge.dart';
import '../../../services/tools_service.dart';

class RomHasherTab extends StatefulWidget {
  final ThemeConfig theme;
  const RomHasherTab({super.key, required this.theme});

  @override
  State<RomHasherTab> createState() => _RomHasherTabState();
}

class _RomHasherTabState extends State<RomHasherTab> {
  final _service = ToolsService();
  String? _filePath;
  bool _isHashing = false;
  bool _isDragging = false;
  double _progress = 0.0;
  String _statusMsg = '';
  HashResult? _result;

  // Hasheous identification state.
  bool _isIdentifying = false;
  HasheousLookupResult? _identify;
  bool _hasheousEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadHasheousPref();
  }

  Future<void> _loadHasheousPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _hasheousEnabled = prefs.getBool(OnlinePrefs.hasheousEnabled) ?? false;
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFile();
    final path = result?.path;
    if (path != null) _setFile(path);
  }

  void _setFile(String path) {
    setState(() {
      _filePath = path;
      _result = null;
      _identify = null;
      _statusMsg = '';
    });
    // Opt-in one-click flow: dropping a file hashes and identifies it.
    if (_hasheousEnabled) _hash();
  }

  Future<void> _hash() async {
    final path = _filePath;
    if (path == null || _isHashing) return;

    setState(() {
      _isHashing = true;
      _progress = 0.0;
      _result = null;
      _identify = null;
      _statusMsg = 'Hashing ${p.basename(path)}…';
    });

    try {
      final res = await _service.hashRom(
        path,
        onProgress: (pct) {
          if (mounted) setState(() => _progress = pct);
        },
      );
      if (!mounted) return;
      setState(() {
        _result = res;
        _progress = 100.0;
        _statusMsg = '';
      });
      // Privacy: only reach the network when the user opted in.
      if (_hasheousEnabled) await _identifyRom();
    } on OpenROMException catch (e) {
      if (mounted) {
        setState(() => _statusMsg = 'Error: ${e.details ?? e.error}');
        showOpenROMError(context, e.error, details: e.details);
      }
    } catch (e) {
      if (mounted) setState(() => _statusMsg = 'Error: $e');
    } finally {
      if (mounted) setState(() => _isHashing = false);
    }
  }

  /// Looks the current hash up on Hasheous. Never throws: failures surface as
  /// an unmatched [HasheousLookupResult] carrying an error message.
  Future<void> _identifyRom() async {
    final res = _result;
    if (res == null || _isIdentifying) return;

    setState(() {
      _isIdentifying = true;
      _identify = null;
    });

    final client = HasheousClient();
    try {
      final lookup = await client.lookupByHash(
        sha1: res.sha1,
        md5: res.md5,
        crc: res.crc32,
      );
      if (mounted) setState(() => _identify = lookup);
    } finally {
      client.close();
      if (mounted) setState(() => _isIdentifying = false);
    }
  }

  Future<void> _copy(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard')),
    );
  }

  Future<void> _copyAll() async {
    final r = _result;
    if (r == null) return;
    final text = 'File:    ${r.filePath}\n'
        'Size:    ${r.size} bytes (${r.sizeHuman})\n'
        'CRC32:   ${r.crc32}\n'
        'MD5:     ${r.md5}\n'
        'SHA-1:   ${r.sha1}\n'
        'SHA-256: ${r.sha256}';
    await _copy('All checksums', text);
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
        if (detail.files.isNotEmpty) {
          _setFile(detail.files.first.path);
        }
      },
      child: Container(
        color: _isDragging
            ? theme.accent.withValues(alpha: 0.1)
            : theme.background,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.fingerprint, color: theme.accent, size: 28),
                  const SizedBox(width: 10),
                  Text(
                    l10n.toolsTabHasher,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                l10n.toolsHasherIntro,
                style: TextStyle(fontSize: 12, color: theme.textSecondary),
              ),
              const SizedBox(height: 16),

              // Drop zone / file picker
              InkWell(
                onTap: _isHashing ? null : _pickFile,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 28,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _isDragging ? theme.accent : Colors.white12,
                      width: _isDragging ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.upload_file,
                        size: 36,
                        color: theme.accent,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _filePath == null
                            ? l10n.toolsHasherDrop
                            : p.basename(_filePath!),
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_filePath != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _filePath!,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.folder_open, size: 16),
                    label: Text(l10n.toolsChooseFile),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.surface,
                      foregroundColor: theme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed:
                        (_filePath != null && !_isHashing) ? _hash : null,
                    icon: _isHashing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.fingerprint, size: 16),
                    label: Text(l10n.toolsComputeHashes),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.accent,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),

              if (_isHashing) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: _progress / 100.0,
                  backgroundColor: theme.surface,
                  color: theme.accent,
                ),
                const SizedBox(height: 6),
                Text(
                  '${_progress.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 12, color: theme.textSecondary),
                ),
              ],

              if (_statusMsg.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  _statusMsg,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.accent,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],

              if (_result != null) ...[
                const SizedBox(height: 18),
                Row(
                  children: [
                    Text(
                      l10n.toolsResults,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _copyAll,
                      icon: const Icon(Icons.copy_all, size: 16),
                      label: Text(l10n.toolsCopyAll),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      _hashRow(l10n.toolsFileSize,
                          '${_result!.size} bytes (${_result!.sizeHuman})'),
                      _hashRow('CRC32', _result!.crc32),
                      _hashRow('MD5', _result!.md5),
                      _hashRow('SHA-1', _result!.sha1),
                      _hashRow('SHA-256', _result!.sha256),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildIdentifySection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// "Identify Game (Hasheous)" action plus its loading / result / no-match
  /// states, shown beneath the hash cards.
  Widget _buildIdentifySection() {
    final l10n = AppLocalizations.of(context);
    final theme = widget.theme;
    final lookup = _identify;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _isIdentifying ? null : _identifyRom,
              icon: _isIdentifying
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.travel_explore, size: 16),
              label: Text(
                _isIdentifying ? l10n.toolsIdentifying : l10n.toolsIdentifyGame,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.accent,
                foregroundColor: Colors.black,
              ),
            ),
            const SizedBox(width: 10),
            if (!_hasheousEnabled)
              Expanded(
                child: Text(
                  l10n.toolsHasheousHint,
                  style: TextStyle(fontSize: 11, color: theme.textSecondary),
                ),
              ),
          ],
        ),
        if (lookup != null) ...[
          const SizedBox(height: 14),
          HasheousResultCard.fromLookup(context, lookup),
        ],
      ],
    );
  }

  Widget _hashRow(String label, String value) {
    final theme = widget.theme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: theme.textPrimary,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Copy $label',
            iconSize: 16,
            onPressed: () => _copy(label, value),
            icon: Icon(Icons.copy, color: theme.accent),
          ),
        ],
      ),
    );
  }
}
