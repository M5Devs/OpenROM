// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3 + Commons Clause

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openrom_flutter/core/errors.dart';
import 'package:openrom_flutter/services/core_bridge.dart';

void main() {
  group('OpenROMError tests', () {
    test('All OpenROMError values have non-null properties', () {
      for (final err in OpenROMError.values) {
        expect(err.title, isNotEmpty);
        expect(err.message, isNotEmpty);
        expect(err.action, isNotEmpty);
        expect(err.actionLabel, isNotEmpty);
        expect(err.icon, isA<IconData>());
        expect(err.color, isA<Color>());
      }
    });

    test('Specific error properties match requirements', () {
      expect(OpenROMError.coreNotFound.title, 'Backend Not Found');
      expect(OpenROMError.coreNotFound.color, Colors.red);
      expect(OpenROMError.coreNotFound.actionLabel, 'Open GitHub');

      expect(OpenROMError.unsupportedFormat.title, 'Unsupported Format');
      expect(OpenROMError.unsupportedFormat.color, Colors.orange);

      expect(OpenROMError.diskSpaceLow.title, 'Low Disk Space');
      expect(OpenROMError.diskSpaceLow.actionLabel, 'Retry');

      expect(OpenROMError.toolFailed.title, 'Tool Crashed');
      expect(OpenROMError.toolFailed.color, Colors.red);

      expect(OpenROMError.conversionFailed.title, 'Conversion Failed');
      expect(OpenROMError.conversionFailed.actionLabel, 'View Log');

      expect(OpenROMError.fileNotFound.title, 'File Not Found');
      expect(OpenROMError.fileNotFound.color, Colors.orange);

      expect(OpenROMError.outputDirNotFound.title, 'Output Folder Missing');
      expect(OpenROMError.permissionDenied.title, 'Permission Denied');
      expect(OpenROMError.corruptedFile.title, 'Corrupted File');
      expect(OpenROMError.unknownError.title, 'Unexpected Error');
    });

    test('OpenROMException formats correctly', () {
      final ex = OpenROMException(OpenROMError.coreNotFound, details: 'Missing executable');
      expect(ex.error, OpenROMError.coreNotFound);
      expect(ex.details, 'Missing executable');
      expect(ex.toString(), contains('OpenROMException'));
      expect(ex.toString(), contains('coreNotFound'));
    });
  });
}
