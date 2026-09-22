// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import '../core/errors.dart';
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
  String? estimatedOutputSize;
  OpenROMError? error;

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
    this.estimatedOutputSize,
    this.error,
  }) : logs = logs ?? [];

  static String estimateSize(
    int fileSizeBytes,
    String targetFormat,
    String compression,
  ) {
    double ratio;
    switch (targetFormat.toUpperCase()) {
      case 'CHD':
        ratio = 0.60;
        break;
      case 'CSO':
        ratio = compression == 'Max'
            ? 0.60
            : compression == 'Fast'
            ? 0.80
            : 0.70;
        break;
      case 'RVZ':
        ratio = compression == 'Max' ? 0.50 : 0.55;
        break;
      case 'ECM':
        ratio = 0.95;
        break;
      case 'ZIP':
        ratio = compression == 'Max' ? 0.65 : 0.75;
        break;
      case '7Z':
        ratio = compression == 'Max' ? 0.55 : 0.65;
        break;
      default:
        return '';
    }

    final estimated = (fileSizeBytes * ratio).round();
    if (estimated < 1024 * 1024) {
      return '~${(estimated / 1024).toStringAsFixed(0)} KB';
    } else if (estimated < 1024 * 1024 * 1024) {
      return '~${(estimated / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '~${(estimated / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

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
