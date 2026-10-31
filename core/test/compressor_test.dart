import 'dart:io';

import 'package:openrom_core/openrom_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('Compressor throws UnsupportedError when 7z format is requested', () {
    final tmpDir = Directory.systemTemp.createTempSync('compressor_7z_test_');
    try {
      final sampleFile = p.join(tmpDir.path, 'sample.rom');
      File(sampleFile).writeAsBytesSync([1, 2, 3, 4, 5]);

      final compressor = Compressor();
      final job = CompressionJob(
        filepath: sampleFile,
        outputDir: tmpDir.path,
        format: '7z',
      );

      expect(() => compressor.compress(job), throwsA(isA<UnsupportedError>()));
    } finally {
      tmpDir.deleteSync(recursive: true);
    }
  });

  test('Compressor extracts zip archive using streams', () {
    final tmpDir =
        Directory.systemTemp.createTempSync('compressor_extract_test_');
    try {
      final sampleFile = p.join(tmpDir.path, 'test_game.iso');
      final testData = List<int>.generate(1024 * 100, (i) => i % 256);
      File(sampleFile).writeAsBytesSync(testData);

      final compressor = Compressor();
      final compressJob = CompressionJob(
        filepath: sampleFile,
        outputDir: tmpDir.path,
        format: 'zip',
      );

      final compressOk = compressor.compress(compressJob);
      expect(compressOk, isTrue);

      final zipPath = p.join(tmpDir.path, 'test_game.zip');
      expect(File(zipPath).existsSync(), isTrue);

      final extractDir = p.join(tmpDir.path, 'extracted');
      final extractJob = CompressionJob(
        filepath: zipPath,
        outputDir: extractDir,
        format: 'extract',
      );

      final extractOk = compressor.extract(extractJob);
      expect(extractOk, isTrue);

      final extractedFile = p.join(extractDir, 'test_game.iso');
      expect(File(extractedFile).existsSync(), isTrue);
      expect(File(extractedFile).lengthSync(), equals(testData.length));
    } finally {
      tmpDir.deleteSync(recursive: true);
    }
  });
}
