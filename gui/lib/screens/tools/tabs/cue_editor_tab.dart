// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../models/theme_config.dart';

class CueEditorTab extends StatefulWidget {
  final ThemeConfig theme;
  const CueEditorTab({super.key, required this.theme});

  @override
  State<CueEditorTab> createState() => _CueEditorTabState();
}

class _CueEditorTabState extends State<CueEditorTab> {
  String? _cuePath;
  final TextEditingController _controller = TextEditingController();
  bool _hasChanges = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickCueFile() async {
    final result = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['cue'],
    );
    if (result?.path != null) {
      final path = result!.path!;
      final content = await File(path).readAsString();
      setState(() {
        _cuePath = path;
        _controller.text = content;
        _hasChanges = false;
      });
    }
  }

  Future<void> _saveCueFile() async {
    if (_cuePath == null) return;
    setState(() => _isSaving = true);
    try {
      await File(_cuePath!).writeAsString(_controller.text);
      setState(() => _hasChanges = false);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _pickCueFile,
                icon: const Icon(Icons.folder_open, size: 16),
                label: const Text('Open .cue'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _hasChanges && !_isSaving ? _saveCueFile : null,
                icon: _isSaving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save, size: 16),
                label: const Text('Save'),
              ),
              if (_cuePath != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _cuePath!,
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.theme.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: widget.theme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: widget.theme.border),
              ),
              child: TextField(
                controller: _controller,
                onChanged: (_) => setState(() => _hasChanges = true),
                maxLines: null,
                expands: true,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(12),
                  border: InputBorder.none,
                  hintText:
                      _cuePath == null ? 'Open a .cue file to edit...' : null,
                  hintStyle: TextStyle(color: widget.theme.textSecondary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
