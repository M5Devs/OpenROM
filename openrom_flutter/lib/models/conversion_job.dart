// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3 + Commons Clause

import 'rom_file.dart';

enum JobStatus { queued, converting, done, failed }

class ConversionJob {
  final String id;
  final RomFile romFile;
  String targetFormat;
  String compression;
  bool verify;
  JobStatus status;
  double progress;
  List<String> logs;
  String? errorMessage;

  ConversionJob({
    required this.id,
    required this.romFile,
    required this.targetFormat,
    this.compression = 'Normal',
    this.verify = false,
    this.status = JobStatus.queued,
    this.progress = 0.0,
    List<String>? logs,
    this.errorMessage,
  }) : logs = logs ?? [];

  String get statusText {
    switch (status) {
      case JobStatus.queued:
        return 'Waiting...';
      case JobStatus.converting:
        return 'Converting... ${progress.toStringAsFixed(1)}%';
      case JobStatus.done:
        return '✅ Done';
      case JobStatus.failed:
        return '❌ Failed';
    }
  }
}
