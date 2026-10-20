import 'dart:io';

import 'package:openrom_core/openrom_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('nes_header_detection_and_removal', () {
    final tmpDir = Directory.systemTemp.createTempSync('hdr_test_');
    try {
      final romPath = p.join(tmpDir.path, 'game.nes');
      final header = [
        0x4E,
        0x45,
        0x53,
        0x1A,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
      ];
      final body = List<int>.filled(100, 0xFF);
      File(romPath).writeAsBytesSync([...header, ...body]);

      final det = detectHeader(romPath);
      expect(det, isNotNull);
      expect(det!['system'], equals('NES'));
      expect(det['has_header'], isTrue);
      expect(det['header_size'], equals(16));

      final outDir = p.join(tmpDir.path, 'output');
      final cleanPath = removeHeader(romPath, outputDir: outDir, backup: false);
      final cleanBytes = File(cleanPath).readAsBytesSync();
      expect(cleanBytes.length, equals(100));
      expect(cleanBytes, equals(body));
    } finally {
      tmpDir.deleteSync(recursive: true);
    }
  });

  test('nes_in_place_header_removal_without_backup', () {
    final tmpDir = Directory.systemTemp.createTempSync('hdr_inplace_test_');
    try {
      final romPath = p.join(tmpDir.path, 'game_inplace.nes');
      final header = [
        0x4E,
        0x45,
        0x53,
        0x1A,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
      ];
      final body = List<int>.generate(200, (i) => (i + 1) % 256);
      File(romPath).writeAsBytesSync([...header, ...body]);

      // Remove header in-place with backup: false (outputDir: null)
      final cleanPath = removeHeader(romPath, outputDir: null, backup: false);
      expect(cleanPath, equals(romPath));

      final cleanFile = File(cleanPath);
      expect(cleanFile.existsSync(), isTrue);

      final cleanBytes = cleanFile.readAsBytesSync();
      expect(cleanBytes.length, equals(200));
      expect(cleanBytes.length, greaterThan(0));
      expect(cleanBytes, equals(body));

      // Ensure no backup file was created
      expect(File('$romPath.bak').existsSync(), isFalse);
      // Ensure no temp file remained
      expect(File('$romPath.tmp').existsSync(), isFalse);
    } finally {
      tmpDir.deleteSync(recursive: true);
    }
  });
}
