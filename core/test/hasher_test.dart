// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:io';
import 'dart:typed_data';

import 'package:openrom_core/openrom_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Well-known checksums for the ASCII string "123456789".
const _vectorCrc32 = 'CBF43926';
const _vectorMd5 = '25f9e794323b453885f5181f1b624d0b';
const _vectorSha1 = 'f7c3bc1d808e04732adf679965ccc34ca7ae3441';
const _vectorSha256 =
    '15e2b0d3c33891ebb0f1ef609ec419420c20e320ce94c65fbc8c3312448eb225';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('openrom_hasher_test_');
  });

  tearDown(() {
    try {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  File writeFile(String name, List<int> bytes) {
    final file = File(p.join(tempDir.path, name))..writeAsBytesSync(bytes);
    return file;
  }

  group('RomHasher', () {
    test('matches the standard "123456789" test vectors', () async {
      final file = writeFile('vector.bin', '123456789'.codeUnits);
      final result = await RomHasher().hashFile(file.path);

      expect(result, isNotNull);
      expect(result!.crc32, _vectorCrc32);
      expect(result.md5, _vectorMd5);
      expect(result.sha1, _vectorSha1);
      expect(result.sha256, _vectorSha256);
      expect(result.size, 9);
      expect(result.sizeHuman, '9.0 B');
    });

    test('chunked streaming equals a single-shot hash across chunk sizes',
        () async {
      final bytes = Uint8List.fromList(
        List<int>.generate(300 * 1024, (i) => i % 256),
      );
      final file = writeFile('big.bin', bytes);

      final whole =
          await RomHasher(chunkSize: bytes.length).hashFile(file.path);
      final tiny = await RomHasher(chunkSize: 4096).hashFile(file.path);
      final odd = await RomHasher(chunkSize: 7777).hashFile(file.path);

      for (final r in [whole!, tiny!, odd!]) {
        expect(r.size, bytes.length);
        expect(r.md5, whole.md5);
        expect(r.sha1, whole.sha1);
        expect(r.sha256, whole.sha256);
        expect(r.crc32, whole.crc32);
      }
    });

    test('empty file yields the canonical empty digests', () async {
      final file = writeFile('empty.bin', const []);
      final result = await RomHasher().hashFile(file.path);

      expect(result, isNotNull);
      expect(result!.crc32, '00000000');
      expect(result.md5, 'd41d8cd98f00b204e9800998ecf8427e');
      expect(result.sha1, 'da39a3ee5e6b4b0d3255bfef95601890afd80709');
      expect(result.sha256,
          'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855');
      expect(result.size, 0);
    });

    test('returns null for a missing file', () async {
      final result =
          await RomHasher().hashFile(p.join(tempDir.path, 'nope.bin'));
      expect(result, isNull);
    });

    test('reports monotonic progress ending at 100%', () async {
      final file = writeFile(
        'progress.bin',
        Uint8List.fromList(List<int>.filled(200 * 1024, 7)),
      );
      final seen = <double>[];
      await RomHasher(chunkSize: 8192).hashFile(
        file.path,
        onProgress: seen.add,
      );

      expect(seen, isNotEmpty);
      expect(seen.last, closeTo(100.0, 0.001));
      for (var i = 1; i < seen.length; i++) {
        expect(seen[i], greaterThanOrEqualTo(seen[i - 1]));
      }
    });

    test('formatBytes renders human-readable sizes', () {
      expect(formatBytes(0), '0.0 B');
      expect(formatBytes(512), '512.0 B');
      expect(formatBytes(1024), '1.0 KB');
      expect(formatBytes(1536), '1.5 KB');
      expect(formatBytes(5 * 1024 * 1024), '5.0 MB');
      expect(formatBytes(3 * 1024 * 1024 * 1024), '3.0 GB');
    });
  });
}
