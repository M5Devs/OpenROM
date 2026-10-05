// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../models/conversion_job.dart';
import '../models/errors.dart';
import '../services/core_bridge.dart';
import '../services/file_detector.dart';

class HomeController extends ChangeNotifier {
  final List<ConversionJob> _jobs = [];
  final List<String> _logs = [];
  bool _isConverting = false;
  bool _showTerminal = false;

  List<ConversionJob> get jobs => List.unmodifiable(_jobs);
  List<String> get logs => List.unmodifiable(_logs);
  bool get isConverting => _isConverting;
  bool get showTerminal => _showTerminal;
  int get fileCount => _jobs.length;

  void toggleTerminal(bool show) {
    _showTerminal = show;
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  void addFilesFromPaths(
    List<String> paths, {
    void Function(OpenROMException e)? onError,
  }) async {
    try {
      final roms = await FileDetector.detectPaths(paths);
      for (final rom in roms) {
        if (!_jobs.any((j) => j.romFile.filepath == rom.filepath)) {
          final defaultTarget =
              rom.validTargets.isNotEmpty ? rom.validTargets.first : 'CHD';
          _jobs.add(
            ConversionJob(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              romFile: rom,
              targetFormat: defaultTarget,
            ),
          );
        }
      }
      notifyListeners();
    } on OpenROMException catch (e) {
      if (onError != null) {
        onError(e);
      }
    }
  }

  void pickFiles({
    void Function(OpenROMException e)? onError,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );
    if (result != null) {
      final paths = result.paths.whereType<String>().toList();
      addFilesFromPaths(paths, onError: onError);
    }
  }

  void startConversion({
    String? globalFormat,
    String compression = 'Normal',
    bool verify = false,
    String outputDir = '',
    Future<String?> Function(ConversionJob job)? onPromptMedia,
    void Function(OpenROMException e)? onError,
  }) async {
    if (_jobs.isEmpty || _isConverting) return;

    _isConverting = true;
    _showTerminal = true;
    _logs.add('[START] Batch conversion started at ${DateTime.now()}');
    notifyListeners();

    for (final job in _jobs) {
      if (globalFormat != null && globalFormat.isNotEmpty) {
        if (job.romFile.validTargets.contains(globalFormat) ||
            globalFormat == 'BIN/CUE') {
          job.targetFormat = globalFormat;
        }
      }
      job.compression = compression;
      job.verify = verify;
      job.estimatedOutputSize = ConversionJob.estimateSize(
        job.romFile.fileSizeBytes ?? 0,
        job.targetFormat,
        job.compression,
      );

      if (job.targetFormat.toUpperCase() == 'CHD' &&
          (job.romFile.platform == 'UNKNOWN' ||
              job.romFile.platform == 'Unknown Disc' ||
              job.romFile.platform == 'ROM File') &&
          (job.media == null || job.media!.isEmpty)) {
        if (onPromptMedia != null) {
          final choice = await onPromptMedia(job);
          if (choice != null && choice.isNotEmpty) {
            job.media = choice;
          } else {
            job.status = JobStatus.failed;
            job.errorMessage =
                'Error: Platform could not be detected. Please specify media type.';
            job.error = OpenROMError.conversionFailed;
            _logs.add('[ERROR] ${job.errorMessage}');
            notifyListeners();
            continue;
          }
        }
      }

      job.status = JobStatus.converting;
      notifyListeners();

      try {
        await CoreBridge.runConversion(
          job: job,
          outputDir: outputDir,
          onProgress: (pct) {
            job.progress = pct;
            notifyListeners();
          },
          onLog: (logMsg) {
            job.logs.add(logMsg);
            _logs.add(logMsg);
            notifyListeners();
          },
          onDone: (success, err) {
            job.status = success ? JobStatus.done : JobStatus.failed;
            job.errorMessage = err;
            if (!success) {
              job.error = OpenROMError.conversionFailed;
            }
            if (err != null && err.isNotEmpty) {
              _logs.add('[ERROR] $err');
            }
            notifyListeners();
          },
        );
      } on OpenROMException catch (e) {
        job.status = JobStatus.failed;
        job.error = e.error;
        job.errorMessage = e.details ?? e.error.message;
        _logs.add(
          '[ERROR] ${e.error.title}: ${e.details ?? e.error.message}',
        );
        notifyListeners();
        if (onError != null) {
          onError(e);
        }
      }
    }

    _isConverting = false;
    _logs.add('[FINISHED] All jobs processed.');
    notifyListeners();
  }

  void removeJob(int index) {
    if (_isConverting) return;
    _jobs.removeAt(index);
    notifyListeners();
  }

  void clearCompleted() {
    _jobs.removeWhere(
      (j) => j.status == JobStatus.done || j.status == JobStatus.failed,
    );
    notifyListeners();
  }

  void reorderJobs(int oldIndex, int newIndex) {
    if (_isConverting) return;
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final job = _jobs.removeAt(oldIndex);
    _jobs.insert(newIndex, job);
    notifyListeners();
  }
}
