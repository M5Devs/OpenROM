import 'dart:io';
import 'package:openrom_core/openrom_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('crc32_calculation', () {
    final tmpDir = Directory.systemTemp.createTempSync('crc_test_');
    try {
      final testFile = p.join(tmpDir.path, 'test.bin');
      File(testFile).writeAsStringSync('123456789');

      final crc = calcCrc32(testFile);
      expect(crc, equals('cbf43926'));
    } finally {
      tmpDir.deleteSync(recursive: true);
    }
  });
}
