// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../widgets/error_dialog.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/theme_config.dart';
import '../../../services/core_bridge.dart';
import '../../../services/tools_service.dart';

class WatchFolderTab extends StatefulWidget {
  final ThemeConfig theme;
  const WatchFolderTab({super.key, required this.theme});

  @override
  State<WatchFolderTab> createState() => _WatchFolderTabState();
}

class _WatchFolderTabState extends State<WatchFolderTab>
    with SingleTickerProviderStateMixin {
  static const List<String> _formats = [
    'CHD',
    'RVZ',
    'CSO',
    'ECM',
    'ISO',
    'BIN/CUE'
  ];

  final WatchFolderSession _session = WatchFolderSession();
  final List<String> _logLines = [];

  String _inputDir = '';
  String _outputDir = '';
  String _format = 'CHD';
  bool _deleteSource = false;
  bool _isWatching = false;
  bool _isStarting = false;

  AppLocalizations get _l10n => AppLocalizations.of(context);

  // Runs only while watching; a permanently repeating controller would make
  // `pumpAndSettle` never settle in widget tests.
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void dispose() {
    _pulseController.dispose();
    _session.stop();
    super.dispose();
  }

  Future<void> _pickInput() async {
    final dir = await FilePicker.getDirectoryPath();
    if (dir != null && dir.isNotEmpty) {
      setState(() => _inputDir = dir);
    }
  }

  Future<void> _pickOutput() async {
    final dir = await FilePicker.getDirectoryPath();
    if (dir != null && dir.isNotEmpty) {
      setState(() => _outputDir = dir);
    }
  }

  void _appendLog(String line) {
    if (!mounted) return;
    final stamp = DateTime.now().toIso8601String().substring(11, 19);
    setState(() => _logLines.add('[$stamp] $line'));
  }

  Future<void> _toggleWatching() async {
    if (_isWatching) {
      await _session.stop();
      if (mounted) {
        _pulseController.stop();
        setState(() => _isWatching = false);
        _appendLog(_l10n.toolsWatchStopped);
      }
      return;
    }

    if (_inputDir.isEmpty || _outputDir.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_l10n.toolsWatchNeedFolders)),
      );
      return;
    }

    setState(() => _isStarting = true);
    try {
      await _session.start(
        inputDir: _inputDir,
        outputDir: _outputDir,
        format: _format,
        deleteSource: _deleteSource,
        onEvent: (event) {
          if (!mounted) return;
          switch (event.type) {
            case 'progress':
              _appendLog('${event.file}: ${event.percent.toStringAsFixed(1)}%');
              break;
            case 'done':
              _appendLog(event.success
                  ? '✅ Converted ${event.file}'
                  : '❌ Failed ${event.file}: ${event.error ?? ''}');
              break;
            case 'error':
              _appendLog('⚠ ${event.message}');
              break;
            default:
              _appendLog(event.message);
          }
        },
        onError: (e) => _appendLog('Error: $e'),
      );
      if (mounted) {
        _pulseController.repeat(reverse: true);
        setState(() {
          _isWatching = true;
          _isStarting = false;
        });
        _appendLog('Watching $_inputDir → $_outputDir ($_format).');
      }
    } on OpenROMException catch (e) {
      if (mounted) {
        setState(() => _isStarting = false);
        showOpenROMError(context, e.error, details: e.details);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isStarting = false);
        _appendLog('Error: $e');
      }
    }
  }

  Widget _dirPicker({
    required String label,
    required String value,
    required VoidCallback onPick,
  }) {
    final theme = widget.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: theme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onPick,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                Icon(Icons.folder_outlined, size: 18, color: theme.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value.isEmpty ? _l10n.toolsChooseFolder : value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: value.isEmpty
                          ? theme.textSecondary
                          : theme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = widget.theme;

    return Container(
      color: theme.background,
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.folder_shared_outlined,
                    color: theme.accent, size: 28),
                const SizedBox(width: 10),
                Text(
                  l10n.toolsWatchTitle,
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
              l10n.toolsWatchIntro,
              style: TextStyle(fontSize: 12, color: theme.textSecondary),
            ),
            const SizedBox(height: 20),

            _dirPicker(
              label: l10n.toolsInputFolder,
              value: _inputDir,
              onPick: _pickInput,
            ),
            const SizedBox(height: 16),
            _dirPicker(
              label: l10n.toolsOutputFolder,
              value: _outputDir,
              onPick: _pickOutput,
            ),
            const SizedBox(height: 20),

            Text(
              l10n.toolsTargetFormat,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: theme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _formats.map((fmt) {
                final selected = _format == fmt;
                return ChoiceChip(
                  label: Text(fmt),
                  selected: selected,
                  selectedColor: theme.accent,
                  backgroundColor: theme.surface,
                  labelStyle: TextStyle(
                    color: selected ? Colors.black : theme.textPrimary,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (_) => setState(() => _format = fmt),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Switch(
                  value: _deleteSource,
                  activeThumbColor: theme.accent,
                  onChanged: (v) => setState(() => _deleteSource = v),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.toolsDeleteSource,
                  style: TextStyle(fontSize: 13, color: theme.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Start/stop control with a green pulse while active.
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isStarting ? null : _toggleWatching,
                  icon: _isStarting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _isWatching ? Icons.stop : Icons.play_arrow,
                          size: 18,
                        ),
                  label: Text(_isWatching
                      ? l10n.toolsStopWatching
                      : l10n.toolsStartWatching),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isWatching ? Colors.redAccent : theme.accent,
                    foregroundColor: _isWatching ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(width: 14),
                if (_isWatching)
                  FadeTransition(
                    opacity: Tween<double>(begin: 0.3, end: 1.0)
                        .animate(_pulseController),
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                if (_isWatching) ...[
                  const SizedBox(width: 8),
                  Text(
                    l10n.toolsActive,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.greenAccent,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),

            Text(
              l10n.toolsLiveLog,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: theme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 220,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
              child: _logLines.isEmpty
                  ? Text(
                      l10n.toolsNoActivity,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  : ListView.builder(
                      itemCount: _logLines.length,
                      itemBuilder: (context, i) => Text(
                        _logLines[i],
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: theme.terminalText,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
