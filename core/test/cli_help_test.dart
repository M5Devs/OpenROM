import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

/// Runs the real CLI entrypoint and captures its output.
ProcessResult _runCli(List<String> args) {
  return Process.runSync(
    Platform.resolvedExecutable,
    ['bin/openrom.dart', ...args],
  );
}

void main() {
  group('CLI --help', () {
    test('--help prints usage and exits 0', () {
      final r = _runCli(['--help']);
      expect(r.exitCode, 0);
      final out = r.stdout as String;
      expect(out, contains('Usage: openrom-core [options]'));
      expect(out, contains('--help'));
      expect(out, contains('--input'));
    });

    test('-h prints usage and exits 0', () {
      final r = _runCli(['-h']);
      expect(r.exitCode, 0);
      expect(r.stdout as String, contains('Usage: openrom-core [options]'));
    });

    test('--help advertises the --identify flag', () {
      final r = _runCli(['--help']);
      expect(r.exitCode, 0);
      expect(r.stdout as String, contains('--identify'));
    });

    test('no arguments prints usage and exits 0', () {
      final r = _runCli([]);
      expect(r.exitCode, 0);
      expect(r.stdout as String, contains('Usage: openrom-core [options]'));
    });

    test('unknown option exits 2 with an error and usage on stderr', () {
      final r = _runCli(['--not-a-real-option']);
      expect(r.exitCode, 2);
      expect(r.stderr as String, contains('Error parsing arguments'));
      expect(r.stderr as String, contains('Usage: openrom-core [options]'));
    });

    test('--version exits 0 and prints only the version line', () {
      final r = _runCli(['--version']);
      expect(r.exitCode, 0);
      // Plugin loading must not run for `--version`, so nothing may precede it.
      expect(
        (r.stdout as String).trim(),
        matches(RegExp(r'^OpenROM( v[0-9][0-9.]*)?$')),
      );
    });
  });

  group('CLI decoupled routes', () {
    test('converting to a decoupled format reports the extension message', () {
      final tmpDir = Directory.systemTemp.createTempSync('cli_decoupled_');
      try {
        final iso = File('${tmpDir.path}/game.iso')
          ..writeAsBytesSync(List<int>.filled(2048, 0));

        final r = _runCli([
          '--input',
          iso.path,
          '--format',
          'XISO',
          '--json',
          '--output',
          tmpDir.path,
        ]);

        expect(r.exitCode, 1);
        final out = r.stdout as String;
        expect(
          out,
          contains('Format requires a community extension '
              '(e.g. NKit or Xbox Suite).'),
        );
        expect(out, contains('OpenROM Extension Store'));
      } finally {
        tmpDir.deleteSync(recursive: true);
      }
    });
  });

  group('CLI batch metrics', () {
    test('a single-job completion payload carries the space-saved fields', () {
      final tmpDir = Directory.systemTemp.createTempSync('cli_metrics_');
      try {
        final iso = File('${tmpDir.path}/game.iso')
          ..writeAsBytesSync(List<int>.filled(2048, 0));

        // The decoupled XISO route fails, but the completion `done` event must
        // still advertise the metrics keys so consumers can rely on the shape.
        final r = _runCli([
          '--input',
          iso.path,
          '--format',
          'XISO',
          '--json',
          '--output',
          tmpDir.path,
        ]);

        final lines = (r.stdout as String)
            .split('\n')
            .where((l) => l.trim().startsWith('{'))
            .map((l) => jsonDecode(l) as Map<String, dynamic>)
            .toList();
        final done = lines.lastWhere((e) => e['type'] == 'done');
        expect(done['success'], isFalse);
        expect(done.containsKey('jobs_completed'), isTrue);
        expect(done.containsKey('original_bytes'), isTrue);
        expect(done.containsKey('output_bytes'), isTrue);
        expect(done.containsKey('bytes_saved'), isTrue);
        expect(done.containsKey('bytes_saved_readable'), isTrue);
        expect(done.containsKey('saved_percentage'), isTrue);
      } finally {
        tmpDir.deleteSync(recursive: true);
      }
    });
  });

  group('CLI --watch', () {
    test('--help advertises --watch and --settle-seconds', () {
      final r = _runCli(['--help']);
      expect(r.exitCode, 0);
      final out = r.stdout as String;
      expect(out, contains('--watch'));
      expect(out, contains('--settle-seconds'));
    });

    test('--watch with a missing directory creates it and logs readiness', () async {
      final tmpDir = Directory.systemTemp.createTempSync('cli_watch_');
      final inDir = Directory('${tmpDir.path}/incoming');
      final outDir = Directory('${tmpDir.path}/library');
      try {
        final process = await Process.start(
          Platform.resolvedExecutable,
          [
            'bin/openrom.dart',
            '--json',
            '--watch',
            inDir.path,
            '--format',
            'CHD',
            '--output',
            outDir.path,
          ],
        );

        final lines = <String>[];
        final sub = process.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(lines.add);

        // Wait for the readiness log, then shut the daemon down.
        final deadline = DateTime.now().add(const Duration(seconds: 20));
        while (DateTime.now().isBefore(deadline) &&
            !lines.any((l) => l.contains('[WATCH] Watching'))) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }

        process.kill();
        await process.exitCode;
        await sub.cancel();

        expect(inDir.existsSync(), isTrue);
        expect(outDir.existsSync(), isTrue);
        final events = lines
            .where((l) => l.trim().startsWith('{'))
            .map((l) => jsonDecode(l) as Map<String, dynamic>)
            .toList();
        expect(
          events.any((e) =>
              e['type'] == 'log' &&
              (e['message'] as String).contains('[WATCH] Watching')),
          isTrue,
        );
      } finally {
        if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
      }
    }, timeout: const Timeout(Duration(seconds: 60)));
  });
}
