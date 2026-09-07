// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3 + Commons Clause

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../core/error_dialog.dart';
import '../core/errors.dart';
import '../l10n/app_localizations.dart';
import '../models/conversion_job.dart';
import '../models/theme_config.dart';
import '../services/core_bridge.dart';
import '../services/file_detector.dart';
import '../widgets/drop_zone.dart';
import '../widgets/rom_card.dart';
import '../widgets/terminal_panel.dart';

class HomeScreen extends StatefulWidget {
  final ThemeConfig theme;

  const HomeScreen({super.key, required this.theme});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final List<ConversionJob> _jobs = [];
  final List<String> _logs = [];
  bool _isConverting = false;
  bool _showTerminal = false;

  int get fileCount => _jobs.length;
  bool get isConverting => _isConverting;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCoreOnStartup();
    });
  }

  Future<void> _checkCoreOnStartup() async {
    try {
      if (!await CoreBridge.coreExists()) {
        throw OpenROMException(OpenROMError.coreNotFound);
      }
    } on OpenROMException catch (e) {
      if (mounted) {
        showOpenROMError(context, e.error, details: e.details);
      }
    }
  }

  void addFilesFromPaths(List<String> paths) async {
    try {
      final roms = await FileDetector.detectPaths(paths);
      for (final rom in roms) {
        if (!_jobs.any((j) => j.romFile.filepath == rom.filepath)) {
          final defaultTarget = rom.validTargets.isNotEmpty ? rom.validTargets.first : 'CHD';
          setState(() {
            _jobs.add(ConversionJob(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              romFile: rom,
              targetFormat: defaultTarget,
            ));
          });
        }
      }
    } on OpenROMException catch (e) {
      if (mounted) {
        showOpenROMError(context, e.error, details: e.details);
      }
    }
  }

  void pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );
    if (result != null) {
      final paths = result.paths.whereType<String>().toList();
      addFilesFromPaths(paths);
    }
  }

  void startConversion({
    String? globalFormat,
    String compression = 'Normal',
    bool verify = false,
    String outputDir = '',
  }) async {
    if (_jobs.isEmpty || _isConverting) return;

    setState(() {
      _isConverting = true;
      _showTerminal = true;
      _logs.add('[START] Batch conversion started at ${DateTime.now()}');
    });

    for (final job in _jobs) {
      if (globalFormat != null && globalFormat.isNotEmpty) {
        if (job.romFile.validTargets.contains(globalFormat) || globalFormat == 'BIN/CUE') {
          job.targetFormat = globalFormat;
        }
      }
      job.compression = compression;
      job.verify = verify;

      setState(() {
        job.status = JobStatus.converting;
      });

      try {
        await CoreBridge.runConversion(
          job: job,
          outputDir: outputDir,
          onProgress: (pct) {
            setState(() {
              job.progress = pct;
            });
          },
          onLog: (logMsg) {
            setState(() {
              job.logs.add(logMsg);
              _logs.add(logMsg);
            });
          },
          onDone: (success, err) {
            setState(() {
              job.status = success ? JobStatus.done : JobStatus.failed;
              job.errorMessage = err;
              if (!success) {
                job.error = OpenROMError.conversionFailed;
              }
              if (err != null && err.isNotEmpty) {
                _logs.add('[ERROR] $err');
              }
            });
          },
        );
      } on OpenROMException catch (e) {
        setState(() {
          job.status = JobStatus.failed;
          job.error = e.error;
          job.errorMessage = e.details ?? e.error.message;
          _logs.add('[ERROR] ${e.error.title}: ${e.details ?? e.error.message}');
        });
        if (mounted) {
          showOpenROMError(context, e.error, details: e.details);
        }
      }
    }

    setState(() {
      _isConverting = false;
      _logs.add('[FINISHED] All jobs processed.');
    });
  }

  void removeJob(int index) {
    if (_isConverting) return;
    setState(() {
      _jobs.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return DropZone(
      theme: widget.theme,
      onFilesDropped: addFilesFromPaths,
      child: Column(
        children: [
          Expanded(
            child: _jobs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.drive_folder_upload, size: 64, color: widget.theme.textSecondary),
                        const SizedBox(height: 16),
                        Text(
                          '${l10n.dropZoneHint}, ${l10n.dropZoneSubHint.toLowerCase()}',
                          style: TextStyle(
                            fontFamily: widget.theme.fontFamily,
                            color: widget.theme.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _jobs.length,
                    itemBuilder: (context, index) {
                      return RomCard(
                        job: _jobs[index],
                        theme: widget.theme,
                        onDelete: () => removeJob(index),
                      );
                    },
                  ),
          ),
          if (_showTerminal)
            TerminalPanel(
              logs: _logs,
              theme: widget.theme,
              onClose: () => setState(() => _showTerminal = false),
              onClear: () => setState(() => _logs.clear()),
            ),
        ],
      ),
    );
  }
}
