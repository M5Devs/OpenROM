import 'dart:io';
import 'package:openrom_core/openrom_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('nes_header_detection_and_removal', () {
    final tmpDir = Directory.systemTemp.createTempSync('hdr_test_');
    try {
      final romPath = p.join(tmpDir.path, 'game.nes');
      final header = [0x4E, 0x45, 0x53, 0x1A, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
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
}
