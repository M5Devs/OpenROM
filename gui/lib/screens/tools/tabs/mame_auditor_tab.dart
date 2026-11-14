// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../widgets/arcade_audit_view.dart';
import '../../../models/theme_config.dart';
import '../../../services/tools_service.dart';

class MameAuditorTab extends StatefulWidget {
  final ThemeConfig theme;
  const MameAuditorTab({super.key, required this.theme});

  @override
  State<MameAuditorTab> createState() => _MameAuditorTabState();
}

class _MameAuditorTabState extends State<MameAuditorTab> {
  final _service = ToolsService();

  String? _datPath;
  String? _romFolder;
  ArcadeAuditReport? _report;
  bool _isAuditing = false;
  String _statusMsg = '';

  Future<void> _pickDat() async {
    final result = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['xml', 'dat'],
    );
    if (result?.path == null) return;
    setState(() {
      _datPath = result!.path;
      _report = null;
    });
  }

  Future<void> _pickFolder() async {
    final path = await FilePicker.getDirectoryPath();
    if (path == null || path.isEmpty) return;
    setState(() {
      _romFolder = path;
      _report = null;
    });
  }

  Future<void> _audit() async {
    if (_datPath == null || _romFolder == null) return;
    setState(() {
      _isAuditing = true;
      _statusMsg = 'Auditing collection…';
      _report = null;
    });
    try {
      final report = await _service.auditMame(
        datPath: _datPath!,
        folderPath: _romFolder!,
      );
      if (!mounted) return;
      setState(() {
        _report = report;
        _statusMsg = '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusMsg = 'Audit failed: $e');
    } finally {
      if (mounted) setState(() => _isAuditing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final report = _report;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Arcade / MAME Manager',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Audit arcade ROM sets against a MAME XML / Logiqx DAT — checks '
            'chip CRCs, BIOS / parent dependencies and CHD images.',
            style: TextStyle(fontSize: 12, color: theme.textSecondary),
          ),
          const SizedBox(height: 16),

          // ── Inputs ─────────────────────────────────────────────────────
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _isAuditing ? null : _pickDat,
                icon: const Icon(Icons.description_outlined, size: 16),
                label: const Text('Select MAME XML / DAT file'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _datPath ?? 'No DAT selected',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: _datPath == null
                        ? theme.textSecondary
                        : theme.textPrimary,
                    fontStyle:
                        _datPath == null ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _isAuditing ? null : _pickFolder,
                icon: const Icon(Icons.folder_open, size: 16),
                label: const Text('Select Arcade ROMs Folder'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _romFolder ?? 'No folder selected',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: _romFolder == null
                        ? theme.textSecondary
                        : theme.textPrimary,
                    fontStyle: _romFolder == null
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: (_isAuditing || _datPath == null || _romFolder == null)
                ? null
                : _audit,
            icon: _isAuditing
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search, size: 16),
            label: const Text('Audit Arcade Collection'),
          ),

          if (_statusMsg.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _statusMsg,
              style: TextStyle(
                fontSize: 12,
                color: theme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          if (report != null) ...[
            const SizedBox(height: 16),
            Expanded(
              child: ArcadeAuditView(report: report, theme: theme),
            ),
          ] else
            const Expanded(child: SizedBox()),
        ],
      ),
    );
  }
}
