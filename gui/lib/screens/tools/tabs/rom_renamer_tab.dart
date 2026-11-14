// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../models/theme_config.dart';
import '../../../services/tools_service.dart';

class RomRenamerTab extends StatefulWidget {
  final ThemeConfig theme;
  const RomRenamerTab({super.key, required this.theme});

  @override
  State<RomRenamerTab> createState() => _RomRenamerTabState();
}

class _RomRenamerTabState extends State<RomRenamerTab> {
  final _service = ToolsService();
  List<Map<String, dynamic>> _dats = [];
  List<Map<String, dynamic>> _scanResults = [];
  String? _romFolder;
  bool _isScanning = false;
  bool _isRenaming = false;
  bool _dryRun = true;
  String _statusMsg = '';

  @override
  void initState() {
    super.initState();
    _loadDats();
  }

  Future<void> _loadDats() async {
    final dats = await _service.listDats();
    setState(() => _dats = dats);
  }

  Future<void> _importDat() async {
    final result = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['dat', 'xml'],
    );
    if (result?.path == null) return;
    try {
      await _service.importDat(result!.path!);
      await _loadDats();
      setState(() => _statusMsg = 'DAT imported successfully');
    } catch (e) {
      setState(() => _statusMsg = 'Import failed: $e');
    }
  }

  Future<void> _removeDat(String storedPath) async {
    await _service.removeDat(storedPath);
    await _loadDats();
  }

  Future<void> _pickFolder() async {
    final path = await FilePicker.getDirectoryPath();
    if (path != null) setState(() => _romFolder = path);
  }

  Future<void> _scan() async {
    if (_romFolder == null || _dats.isEmpty) return;
    setState(() {
      _isScanning = true;
      _scanResults = [];
      _statusMsg = 'Scanning...';
    });
    try {
      final results = await _service.scanRoms(_romFolder!);
      setState(() {
        _scanResults = results;
        _statusMsg = '';
      });
    } catch (e) {
      setState(() => _statusMsg = 'Scan failed: $e');
    } finally {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _rename() async {
    if (_romFolder == null) return;
    setState(() {
      _isRenaming = true;
      _statusMsg = _dryRun ? 'Simulating...' : 'Renaming...';
    });
    try {
      final results = await _service.renameRoms(_romFolder!, dryRun: _dryRun);
      final count = results.where((r) => r['success'] == true).length;
      setState(
        () => _statusMsg = _dryRun
            ? '$count files would be renamed (dry run)'
            : '$count files renamed successfully',
      );
      if (!_dryRun) await _scan();
    } catch (e) {
      setState(() => _statusMsg = 'Rename failed: $e');
    } finally {
      setState(() => _isRenaming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final matched = _scanResults.where((r) => r['matched'] == true).length;
    final unmatched = _scanResults.length - matched;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── DAT Library ──────────────────────────────────────────────
          Text(
            'DAT Library',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: widget.theme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _importDat,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Import DAT'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_dats.isEmpty)
            Text(
              'No DATs imported yet. Import a No-Intro or Redump DAT file.',
              style: TextStyle(color: widget.theme.textSecondary, fontSize: 12),
            )
          else
            Column(
              children: _dats
                  .map(
                    (dat) => ListTile(
                      dense: true,
                      title: Text(
                        dat['name'] ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: widget.theme.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        '${dat['source']} · ${dat['game_count']} games',
                        style: TextStyle(
                          fontSize: 11,
                          color: widget.theme.textSecondary,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 16),
                        onPressed: () => _removeDat(dat['stored_path']),
                        color: Colors.red,
                      ),
                    ),
                  )
                  .toList(),
            ),

          const Divider(height: 24),

          // ── ROM Folder ───────────────────────────────────────────────
          Text(
            'ROM Folder',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: widget.theme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _pickFolder,
                icon: const Icon(Icons.folder_open, size: 16),
                label: const Text('Select Folder'),
              ),
              const SizedBox(width: 12),
              if (_romFolder != null)
                Expanded(
                  child: Text(
                    _romFolder!,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.theme.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: (_isScanning || _dats.isEmpty || _romFolder == null)
                    ? null
                    : _scan,
                icon: _isScanning
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search, size: 16),
                label: const Text('Scan'),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  Checkbox(
                    value: _dryRun,
                    onChanged: (v) => setState(() => _dryRun = v ?? true),
                  ),
                  const Text('Dry run', style: TextStyle(fontSize: 13)),
                ],
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed:
                    (_isRenaming || _scanResults.isEmpty || _romFolder == null)
                        ? null
                        : _rename,
                icon: _isRenaming
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.drive_file_rename_outline, size: 16),
                label: Text(_dryRun ? 'Preview Rename' : 'Rename'),
              ),
            ],
          ),

          if (_statusMsg.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _statusMsg,
              style: TextStyle(
                fontSize: 12,
                color: widget.theme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          // ── Scan Results ─────────────────────────────────────────────
          if (_scanResults.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Results: $matched matched · $unmatched unmatched',
              style: TextStyle(fontSize: 12, color: widget.theme.textSecondary),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _scanResults.length,
                itemBuilder: (context, i) {
                  final r = _scanResults[i];
                  final isMatched = r['matched'] == true;
                  final needsRename =
                      isMatched && r['suggested_filename'] != r['file'];
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      isMatched
                          ? Icons.check_circle_outline
                          : Icons.help_outline,
                      size: 16,
                      color: isMatched ? Colors.green : Colors.grey,
                    ),
                    title: Text(
                      r['file'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.theme.textPrimary,
                      ),
                    ),
                    subtitle: isMatched && needsRename
                        ? Text(
                            '→ ${r['suggested_filename']}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange.shade300,
                            ),
                          )
                        : null,
                  );
                },
              ),
            ),
          ] else
            const Expanded(child: SizedBox()),
        ],
      ),
    );
  }
}
