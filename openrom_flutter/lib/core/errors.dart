// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3 + Commons Clause

import 'package:flutter/material.dart';

enum OpenROMError {
  coreNotFound,        // openrom-core binary missing
  unsupportedFormat,   // file format not in CONVERSION_MAP
  diskSpaceLow,        // not enough space for output
  toolFailed,          // chdman/maxcso/etc crashed
  conversionFailed,    // conversion exited with non-zero code
  fileNotFound,        // input file missing or moved
  outputDirNotFound,   // output directory doesn't exist
  permissionDenied,    // can't write to output directory
  corruptedFile,       // file is unreadable or 0 bytes
  unknownError,        // fallback for anything else
}

extension OpenROMErrorX on OpenROMError {
  String get title {
    switch (this) {
      case OpenROMError.coreNotFound:
        return 'Backend Not Found';
      case OpenROMError.unsupportedFormat:
        return 'Unsupported Format';
      case OpenROMError.diskSpaceLow:
        return 'Low Disk Space';
      case OpenROMError.toolFailed:
        return 'Tool Crashed';
      case OpenROMError.conversionFailed:
        return 'Conversion Failed';
      case OpenROMError.fileNotFound:
        return 'File Not Found';
      case OpenROMError.outputDirNotFound:
        return 'Output Folder Missing';
      case OpenROMError.permissionDenied:
        return 'Permission Denied';
      case OpenROMError.corruptedFile:
        return 'Corrupted File';
      case OpenROMError.unknownError:
        return 'Unexpected Error';
    }
  }

  String get message {
    switch (this) {
      case OpenROMError.coreNotFound:
        return 'openrom-core is missing from the app folder.';
      case OpenROMError.unsupportedFormat:
        return 'This file format cannot be converted with the selected output.';
      case OpenROMError.diskSpaceLow:
        return 'Not enough free space to complete this conversion.';
      case OpenROMError.toolFailed:
        return 'The conversion tool (chdman/maxcso) exited unexpectedly.';
      case OpenROMError.conversionFailed:
        return 'Conversion stopped before completing.';
      case OpenROMError.fileNotFound:
        return 'The input file was moved or deleted.';
      case OpenROMError.outputDirNotFound:
        return 'The selected output folder no longer exists.';
      case OpenROMError.permissionDenied:
        return "OpenROM can't write to the output folder.";
      case OpenROMError.corruptedFile:
        return 'The file appears to be corrupted or is 0 bytes.';
      case OpenROMError.unknownError:
        return 'Something went wrong. This might be a bug.';
    }
  }

  String get action {
    switch (this) {
      case OpenROMError.coreNotFound:
        return 'Please re-download the full ZIP from GitHub.';
      case OpenROMError.unsupportedFormat:
        return 'Check the conversion matrix in the docs.';
      case OpenROMError.diskSpaceLow:
        return 'Free up disk space and try again.';
      case OpenROMError.toolFailed:
        return 'The ROM file might be corrupted or unsupported.';
      case OpenROMError.conversionFailed:
        return 'Check the terminal log for details.';
      case OpenROMError.fileNotFound:
        return 'Re-add the file to the queue.';
      case OpenROMError.outputDirNotFound:
        return 'Choose a different output folder in Settings.';
      case OpenROMError.permissionDenied:
        return 'Choose a folder you have write access to.';
      case OpenROMError.corruptedFile:
        return 'Try re-downloading or re-ripping the ROM.';
      case OpenROMError.unknownError:
        return 'Please report this on GitHub with the terminal log.';
    }
  }

  String get actionLabel {
    switch (this) {
      case OpenROMError.coreNotFound:
        return 'Open GitHub';
      case OpenROMError.unsupportedFormat:
        return 'Open Docs';
      case OpenROMError.diskSpaceLow:
        return 'Retry';
      case OpenROMError.toolFailed:
        return 'Report Bug';
      case OpenROMError.conversionFailed:
        return 'View Log';
      case OpenROMError.fileNotFound:
      case OpenROMError.corruptedFile:
        return 'Close';
      case OpenROMError.outputDirNotFound:
      case OpenROMError.permissionDenied:
        return 'Open Settings';
      case OpenROMError.unknownError:
        return 'Report Bug';
    }
  }

  IconData get icon {
    switch (this) {
      case OpenROMError.coreNotFound:
        return Icons.error_outline;
      case OpenROMError.unsupportedFormat:
        return Icons.block;
      case OpenROMError.diskSpaceLow:
        return Icons.storage;
      case OpenROMError.toolFailed:
        return Icons.build_circle_outlined;
      case OpenROMError.conversionFailed:
        return Icons.cancel_outlined;
      case OpenROMError.fileNotFound:
        return Icons.folder_off_outlined;
      case OpenROMError.outputDirNotFound:
        return Icons.create_new_folder_outlined;
      case OpenROMError.permissionDenied:
        return Icons.lock_outline;
      case OpenROMError.corruptedFile:
        return Icons.broken_image_outlined;
      case OpenROMError.unknownError:
        return Icons.bug_report_outlined;
    }
  }

  Color get color {
    switch (this) {
      case OpenROMError.coreNotFound:
      case OpenROMError.toolFailed:
      case OpenROMError.conversionFailed:
      case OpenROMError.permissionDenied:
      case OpenROMError.corruptedFile:
      case OpenROMError.unknownError:
        return Colors.red;
      case OpenROMError.unsupportedFormat:
      case OpenROMError.diskSpaceLow:
      case OpenROMError.fileNotFound:
      case OpenROMError.outputDirNotFound:
        return Colors.orange;
    }
  }
}
