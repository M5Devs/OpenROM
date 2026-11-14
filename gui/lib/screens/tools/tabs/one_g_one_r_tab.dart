// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../widgets/error_dialog.dart';
import '../../../models/theme_config.dart';
import '../../../services/core_bridge.dart';
import '../../../services/tools_service.dart';

class OneGOneRCleanerTab extends StatefulWidget {
  final ThemeConfig theme;
  const OneGOneRCleanerTab({super.key, required this.theme});

  @override
  State<OneGOneRCleanerTab> createState() => _OneGOneRCleanerTabState();
}

class _OneGOneRCleanerTabState extends State<OneGOneRCleanerTab> {
  final _service = ToolsService();
  String? _romFolder;
  final List<String> _regionPriority = ['USA', 'EUR', 'JPN', 'World'];
  bool _dryRun = true;
  bool _isProcessing = false;
  String _statusMsg = '';
  Map<String, dynamic>? _results;

  Future<void> _pickFolder() async {
    final path = await FilePicker.getDirectoryPath();
    if (path != null) setState(() => _romFolder = path);
  }

  Future<void> _process1G1R() async {
    if (_romFolder == null) return;
    setState(() {
      _isProcessing = true;
      _statusMsg =
          _dryRun ? 'Simulating 1G1R filter...' : 'Cleaning duplicates...';
      _results = null;
    });
    try {
      final res = await _service.filter1G1R(
        folderPath: _romFolder!,
        regionPriority: _regionPriority,
        dryRun: _dryRun,
      );
      setState(() {
        _results = res;
        final moved = res['moved_count'] ?? 0;
        _statusMsg = _dryRun
            ? '$moved duplicates would be moved to _duplicates/'
            : '$moved duplicates moved to _duplicates/';
      });
    } on OpenROMException catch (e) {
      if (mounted) {
        showOpenROMError(context, e.error, details: e.details);
      }
    } catch (e) {
      setState(() => _statusMsg = 'Error: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cleaning_services, color: theme.accent, size: 28),
              const SizedBox(width: 10),
              Text(
                '1G1R Collection Cleaner',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Folder Selection
          Text(
            'ROM Collection Folder',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: theme.textSecondary,
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
                    style: TextStyle(fontSize: 12, color: theme.textSecondary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Region Priority
          Text(
            'Region Priority Order',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: theme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: List.generate(_regionPriority.length, (idx) {
              final reg = _regionPriority[idx];
              return Chip(
                avatar: CircleAvatar(
                  backgroundColor: theme.accent,
                  child: Text(
                    '${idx + 1}',
                    style: const TextStyle(fontSize: 11, color: Colors.black),
                  ),
                ),
                label: Text(reg),
                backgroundColor: theme.surface,
                labelStyle: TextStyle(
                  color: theme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                onDeleted: _regionPriority.length > 1
                    ? () {
                        setState(() => _regionPriority.removeAt(idx));
                      }
                    : null,
              );
            }),
          ),
          const SizedBox(height: 16),

          // Settings & Action
          Row(
            children: [
              Checkbox(
                value: _dryRun,
                activeColor: theme.accent,
                onChanged: (v) => setState(() => _dryRun = v ?? true),
              ),
              Text(
                'Dry Run / Preview',
                style: TextStyle(color: theme.textPrimary),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: (_romFolder != null && !_isProcessing)
                    ? _process1G1R
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                icon: _isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.filter_list, size: 18),
                label: Text(
                  _dryRun ? 'Preview Collection' : 'Process Collection',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

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

          // Results View
          if (_results != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statTile(
                    'Total Files',
                    '${_results!["total_files"]}',
                    theme.textPrimary,
                  ),
                  _statTile(
                    'Kept ROMs',
                    '${_results!["kept_count"]}',
                    Colors.greenAccent,
                  ),
                  _statTile(
                    'Duplicates',
                    '${_results!["moved_count"]}',
                    Colors.orangeAccent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: (_results!['results'] as List? ?? []).length,
                itemBuilder: (context, i) {
                  final item = (_results!['results'] as List)[i];
                  final isWinner = item['is_winner'] == true;
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      isWinner
                          ? Icons.check_circle
                          : Icons.drive_file_move_outlined,
                      color:
                          isWinner ? Colors.greenAccent : Colors.orangeAccent,
                      size: 18,
                    ),
                    title: Text(
                      item['filename'] ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.textPrimary,
                        fontWeight:
                            isWinner ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      isWinner
                          ? 'Kept (${item["clean_title"]})'
                          : 'Duplicate -> _duplicates/',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.textSecondary,
                      ),
                    ),
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

  Widget _statTile(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: widget.theme.textSecondary),
        ),
      ],
    );
  }
}
