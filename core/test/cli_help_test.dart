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
}
