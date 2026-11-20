import 'dart:io';

import 'package:openrom_core/openrom_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Installs a mock maxcso that records its argv, one argument per line.
String _mockMaxcso(String dir) {
  final script = p.join(dir, 'mock_maxcso');
  final argsFile = p.join(dir, 'maxcso_args.txt');
  File(script).writeAsStringSync(
    '#!/bin/sh\nprintf "%s\\n" "\$@" > "$argsFile"\nexit 0\n',
  );
  if (!Platform.isWindows) {
    Process.runSync('chmod', ['+x', script]);
  }
  return script;
}

void main() {
  group('maxcso block size (PSP/PSVita hardware compatibility)', () {
    late Directory tmpDir;

    setUp(() {
      tmpDir = Directory.systemTemp.createTempSync('converter_cso_');
    });

    tearDown(() {
      saveConfig({});
      tmpDir.deleteSync(recursive: true);
    });

    /// Converts [isoPath] to [target] and returns the argv maxcso received.
    Future<List<String>> convertIso(
      String isoPath, {
      required String compression,
      String target = 'CSO',
    }) async {
      saveConfig({'maxcso': _mockMaxcso(tmpDir.path)});

      final job = ConversionJob(
        filepath: isoPath,
        outputDir: tmpDir.path,
        targetFormat: target,
        compression: compression,
      );
      final ok = await Converter().convert(job);
      expect(ok, isTrue, reason: job.error ?? 'conversion failed');

      return File(p.join(tmpDir.path, 'maxcso_args.txt')).readAsLinesSync();
    }

    for (final level in ['Normal', 'High', 'Max']) {
      test('CSO at compression $level pins --block=2048', () async {
        final iso = p.join(tmpDir.path, 'psp_game.iso');
        File(iso).writeAsBytesSync(List<int>.filled(2048, 0));

        final args = await convertIso(iso, compression: level);

        expect(args, contains('--block=2048'));
        expect(
          args.where((a) => a.startsWith('--block=')),
          equals(['--block=2048']),
          reason: 'block size must never be overridden',
        );
        expect(args, isNot(contains('--format=zso')));
        expect(p.extension(args.last), equals('.cso'));
      });
    }

    test('CSO on a multi-gigabyte ISO still pins --block=2048', () async {
      // maxcso raises the block size automatically past its large-ISO
      // threshold, which is exactly the case that broke Adrenaline.
      final iso = p.join(tmpDir.path, 'ps2_game.iso');
      final raf = File(iso).openSync(mode: FileMode.write);
      try {
        raf.truncateSync(6 * 1024 * 1024 * 1024);
      } finally {
        raf.closeSync();
      }

      final args = await convertIso(iso, compression: 'Normal');

      expect(args, contains('--block=2048'));
      expect(
        args.where((a) => a.startsWith('--block=')),
        equals(['--block=2048']),
      );
    });

    test('ZSO pins --block=2048 and requests lz4brute', () async {
      final iso = p.join(tmpDir.path, 'psp_game.iso');
      File(iso).writeAsBytesSync(List<int>.filled(2048, 0));

      final args = await convertIso(iso, compression: 'Max', target: 'ZSO');

      expect(args, contains('--block=2048'));
      expect(args, contains('--format=zso'));
      expect(args, contains('--use-lz4brute'));
      // Deflate methods are invalid inside a ZSO container.
      expect(args, isNot(contains('--use-zopfli')));
      expect(args, isNot(contains('--use-zlib')));
      expect(p.extension(args.last), equals('.zso'));
    });
  });
}
