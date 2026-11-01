// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:openrom_core/openrom_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// Stub 7-Zip helper.
///
/// Generates a POSIX `/bin/sh` script that (a) appends every argv element to a
/// log file in a parseable form, and (b) mimics the subset of 7-Zip behaviour
/// the tests need. All configuration is baked into the script so no environment
/// plumbing is required.
/// ─────────────────────────────────────────────────────────────────────────

const String _defaultCompressBody = r'''
archive=""
prev=""
for a in "$@"; do
  if [ "$prev" = "--" ]; then archive="$a"; break; fi
  prev="$a"
done
if [ -n "$archive" ]; then printf 'STUB7Z' > "$archive"; fi
''';

const String _defaultExtractBody = r'''
outdir=""
prev=""
for a in "$@"; do
  case "$a" in
    -o*) outdir="${a#-o}" ;;
  esac
  if [ "$prev" = "--" ]; then archive="$a"; fi
  prev="$a"
done
mkdir -p "$outdir"
printf 'extracted' > "$outdir/out.bin"
''';

String _writeSevenZipStub(
  Directory dir, {
  required String logPath,
  String? listing,
  int listExit = 0,
  int compressExit = 0,
  int extractExit = 0,
  String? compressBody,
  String? extractBody,
  String name = '7z',
}) {
  final listingBlock = listing == null
      ? ''
      : "cat <<'OPENROM_LISTING_MARKER'\n$listing\nOPENROM_LISTING_MARKER\n";

  final script = '''
#!/bin/sh
LOG="$logPath"
cmd="\$1"
{
  printf 'CMD %s\\n' "\$cmd"
  for a in "\$@"; do printf 'ARG %s\\n' "\$a"; done
} >> "\$LOG"

case "\$cmd" in
  l)
    $listingBlock
    exit $listExit
    ;;
  a)
    ${compressBody ?? _defaultCompressBody}
    echo "WARNING: stub warning" >&2
    echo "ERROR: stub compress failed" >&2
    exit $compressExit
    ;;
  x)
    ${extractBody ?? _defaultExtractBody}
    exit $extractExit
    ;;
esac
exit 0
''';

  final path = p.join(dir.path, name);
  File(path).writeAsStringSync(script);
  Process.runSync('chmod', ['+x', path]);
  return path;
}

/// Parses the stub log into one list of argv elements per invocation.
List<List<String>> _readStubLog(String logPath) {
  final invocations = <List<String>>[];
  for (final line in File(logPath).readAsLinesSync()) {
    if (line.startsWith('CMD ')) {
      invocations.add([line.substring(4)]);
    } else if (line.startsWith('ARG ')) {
      invocations.last.add(line.substring(4));
    }
  }
  return invocations;
}

bool _anyInvocation(List<List<String>> invocations, String cmd) =>
    invocations.any((argv) => argv.isNotEmpty && argv.first == cmd);

String _sha256OfFile(String path) =>
    sha256.convert(File(path).readAsBytesSync()).toString();

/// A real captured `7z l -slt` listing (7-Zip 25.01) used as a fixture.
const String _realListingSample = '''
7-Zip 25.01 (x64) : Copyright (c) 1999-2025 Igor Pavlov : 2025-08-03
 64-bit locale=C.UTF-8 Threads:4 OPEN_MAX:1048576, ASM

Scanning the drive for archives:
1 file, 225 bytes (1 KiB)

Listing archive: sample.7z

--
Path = sample.7z
Type = 7z
Physical Size = 225
Headers Size = 213
Method = LZMA2:12
Solid = +
Blocks = 1

----------
Path = sub
Size = 0
Packed Size = 0
Modified = 2026-11-01 09:51:45.5048655
Attributes = D drwxr-xr-x
CRC =
Encrypted = -
Method =
Block =

Path = Pokémon (Europe).gba
Size = 1
Packed Size = 12
Modified = 2026-11-01 09:51:45.5048655
Attributes = A -rw-r--r--
CRC = 8CDC1683
Encrypted = -
Method = LZMA2:12
Block = 0

Path = a.txt
Size = 6
Packed Size =
Modified = 2026-11-01 09:51:45.5048655
Attributes = A -rw-r--r--
CRC = 363A3020
Encrypted = -
Method = LZMA2:12
Block = 0

Path = sub/b.bin
Size = 1
Packed Size =
Modified = 2026-11-01 09:51:45.5048655
Attributes = A -rw-r--r--
CRC = FBDB2615
Encrypted = -
Method = LZMA2:12
Block = 0
''';

void main() {
  final isPosix = !Platform.isWindows;

  // ── Group 1: stub-based security/argv tests ────────────────────────────
  group('7z stub (argv + safety)', () {
    late Directory tmp;
    late String logPath;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('openrom_7z_stub_');
      logPath = p.join(tmp.path, 'stub.log');
      File(logPath).writeAsStringSync('');
    });

    tearDown(() {
      try {
        if (tmp.existsSync()) tmp.deleteSync(recursive: true);
      } catch (_) {}
    });

    test('compress argv: -- precedes paths, -mx/-t7z/-y present', () {
      final stub = _writeSevenZipStub(tmp, logPath: logPath);
      final src = Directory(p.join(tmp.path, 'src'))..createSync();
      final file = File(p.join(src.path, 'game.iso'))..writeAsStringSync('x');
      final out = Directory(p.join(tmp.path, 'out'))..createSync();

      for (final entry
          in {'fast': '-mx=1', 'normal': '-mx=5', 'ultra': '-mx=9'}.entries) {
        File(logPath).writeAsStringSync('');
        final compressor = Compressor(sevenZip: SevenZip(stub));
        final job = CompressionJob(
          filepath: file.path,
          outputDir: out.path,
          format: '7z',
          level: entry.key,
        );
        expect(compressor.compress(job), isTrue, reason: job.error);

        final invocations = _readStubLog(logPath);
        final argv = invocations.singleWhere((a) => a.first == 'a');
        expect(argv, contains('-t7z'));
        expect(argv, contains('-y'));
        expect(argv, contains(entry.value));
        final dashDash = argv.indexOf('--');
        expect(dashDash, greaterThan(0));
        // Everything after `--` is a path.
        expect(argv.sublist(dashDash + 1).length, 2);
        expect(argv.sublist(dashDash + 1).last, 'game.iso');
      }
    });

    test('extract argv: -o is one element after the subcommand', () {
      final stub = _writeSevenZipStub(
        tmp,
        logPath: logPath,
        listing: _realListingSample,
      );
      final archive = File(p.join(tmp.path, 'a.7z'))..writeAsStringSync('z');
      final out = Directory(p.join(tmp.path, 'out'))..createSync();

      final compressor = Compressor(sevenZip: SevenZip(stub));
      final job = CompressionJob(
        filepath: archive.path,
        outputDir: out.path,
        format: 'extract',
      );
      expect(compressor.extract(job), isTrue, reason: job.error);

      final invocations = _readStubLog(logPath);
      expect(_anyInvocation(invocations, 'l'), isTrue);
      final argv = invocations.singleWhere((a) => a.first == 'x');
      final dashDash = argv.indexOf('--');
      expect(dashDash, greaterThan(0));
      expect(argv[dashDash + 1], archive.path);
      final outArg = argv.singleWhere((a) => a.startsWith('-o'));
      expect(outArg.contains(' '), isFalse);
      expect(outArg, startsWith('-o'));
      expect(argv.where((a) => a.startsWith('-o')).length, 1);
    });

    test('hostile file names stay one argv element and are not executed', () {
      final stub = _writeSevenZipStub(tmp, logPath: logPath);
      final src = Directory(p.join(tmp.path, 'src'))..createSync();
      const hostile = "a; touch PWNED \$(id) 'q'.bin";
      const dashName = '-evil.bin';
      File(p.join(src.path, hostile)).writeAsStringSync('1');
      File(p.join(src.path, dashName)).writeAsStringSync('2');
      final out = Directory(p.join(tmp.path, 'out'))..createSync();

      final compressor = Compressor(sevenZip: SevenZip(stub));

      // Compress the hostile-named file on its own.
      final job = CompressionJob(
        filepath: p.join(src.path, hostile),
        outputDir: out.path,
        format: '7z',
      );
      expect(compressor.compress(job), isTrue, reason: job.error);

      final argv = _readStubLog(logPath).singleWhere((a) => a.first == 'a');
      final dashDash = argv.indexOf('--');
      expect(argv[dashDash + 1], endsWith('.7z.part-$pid'));
      expect(argv[dashDash + 2], hostile);
      // No shell interpretation happened anywhere.
      expect(File(p.join(out.path, 'PWNED')).existsSync(), isFalse);
      expect(
          File(p.join(Directory.current.path, 'PWNED')).existsSync(), isFalse);

      // A name starting with `-` must arrive after `--` intact.
      File(logPath).writeAsStringSync('');
      final job2 = CompressionJob(
        filepath: p.join(src.path, dashName),
        outputDir: out.path,
        format: '7z',
      );
      expect(compressor.compress(job2), isTrue, reason: job2.error);
      final argv2 = _readStubLog(logPath).singleWhere((a) => a.first == 'a');
      final dd2 = argv2.indexOf('--');
      expect(argv2[dd2 + 2], dashName);
    });

    test('existing archive is replaced, never appended', () {
      final stub = _writeSevenZipStub(tmp, logPath: logPath);
      final src = Directory(p.join(tmp.path, 'src'))..createSync();
      final file = File(p.join(src.path, 'game.iso'))..writeAsStringSync('x');
      final out = Directory(p.join(tmp.path, 'out'))..createSync();
      final finalArchive = File(p.join(out.path, 'game.iso.7z'))
        ..writeAsStringSync('OLD-ARCHIVE-CONTENT');

      final compressor = Compressor(sevenZip: SevenZip(stub));
      final job = CompressionJob(
        filepath: file.path,
        outputDir: out.path,
        format: '7z',
      );
      expect(compressor.compress(job), isTrue, reason: job.error);

      // Stub wrote a fresh file; the old content is gone.
      expect(finalArchive.readAsStringSync(), 'STUB7Z');
      // No leftover part file.
      expect(
        out.listSync().where((e) => e.path.contains('.part-')),
        isEmpty,
      );
    });

    test('on stub failure the previous archive is intact and no .part remains',
        () {
      final stub = _writeSevenZipStub(tmp, logPath: logPath, compressExit: 1);
      final src = Directory(p.join(tmp.path, 'src'))..createSync();
      final file = File(p.join(src.path, 'game.iso'))..writeAsStringSync('x');
      final out = Directory(p.join(tmp.path, 'out'))..createSync();
      final finalArchive = File(p.join(out.path, 'game.iso.7z'))
        ..writeAsStringSync('OLD-ARCHIVE-CONTENT');

      final compressor = Compressor(sevenZip: SevenZip(stub));
      final job = CompressionJob(
        filepath: file.path,
        outputDir: out.path,
        format: '7z',
      );
      expect(compressor.compress(job), isFalse);
      expect(job.status, 'Failed');
      expect(finalArchive.readAsStringSync(), 'OLD-ARCHIVE-CONTENT');
      expect(out.listSync().where((e) => e.path.contains('.part-')), isEmpty);
    });

    for (final unsafe in ['../x', '/etc/x', r'C:\x', r'a\..\b']) {
      test('unsafe listing entry "$unsafe" is rejected before extraction', () {
        final listing = '''
--
Path = a.7z
Type = 7z

----------
Path = $unsafe
Size = 1
Attributes = A -rw-r--r--

''';
        final stub = _writeSevenZipStub(
          tmp,
          logPath: logPath,
          listing: listing,
        );
        final archive = File(p.join(tmp.path, 'a.7z'))..writeAsStringSync('z');
        final out = Directory(p.join(tmp.path, 'out'))..createSync();

        final compressor = Compressor(sevenZip: SevenZip(stub));
        final job = CompressionJob(
          filepath: archive.path,
          outputDir: out.path,
          format: 'extract',
        );
        expect(compressor.extract(job), isFalse);
        expect(job.status, 'Failed');
        expect(job.error, contains('unsafe path'));

        final invocations = _readStubLog(logPath);
        expect(_anyInvocation(invocations, 'l'), isTrue);
        // Extraction must never have been attempted.
        expect(_anyInvocation(invocations, 'x'), isFalse);
      });
    }

    test('symlink created by extract is rejected; staging removed', () {
      final stub = _writeSevenZipStub(
        tmp,
        logPath: logPath,
        listing: _realListingSample,
        extractBody: r'''
outdir=""
prev=""
for a in "$@"; do
  case "$a" in
    -o*) outdir="${a#-o}" ;;
  esac
  prev="$a"
done
mkdir -p "$outdir"
ln -s /etc/passwd "$outdir/evil-link"
''',
      );
      final archive = File(p.join(tmp.path, 'a.7z'))..writeAsStringSync('z');
      final out = Directory(p.join(tmp.path, 'out'))..createSync();

      final compressor = Compressor(sevenZip: SevenZip(stub));
      final job = CompressionJob(
        filepath: archive.path,
        outputDir: out.path,
        format: 'extract',
      );
      expect(compressor.extract(job), isFalse);
      expect(job.error, contains('symbolic link'));
      // Nothing moved into outputDir and no staging dir left behind.
      expect(out.listSync(), isEmpty);
    });

    test('stub exit codes 1 and 2 fail with a stderr tail', () {
      for (final code in [1, 2]) {
        final stub = _writeSevenZipStub(
          tmp,
          logPath: logPath,
          listing: _realListingSample,
          extractExit: code,
          extractBody: r'''
outdir=""
for a in "$@"; do case "$a" in -o*) outdir="${a#-o}" ;; esac; done
echo "WARNING: something went wrong line 1" >&2
echo "ERROR: fatal 7z problem line 2" >&2
''',
        );
        final archive = File(p.join(tmp.path, 'a$code.7z'))
          ..writeAsStringSync('z');
        final out = Directory(p.join(tmp.path, 'out$code'))..createSync();

        final compressor = Compressor(sevenZip: SevenZip(stub));
        final job = CompressionJob(
          filepath: archive.path,
          outputDir: out.path,
          format: 'extract',
        );
        expect(compressor.extract(job), isFalse);
        expect(job.status, 'Failed');
        expect(job.error, contains('ERROR: fatal 7z problem line 2'));
      }
    });

    test('missing executable fails cleanly with the not-found message', () {
      final missing = p.join(tmp.path, 'does-not-exist-7z');
      final src = File(p.join(tmp.path, 'game.iso'))..writeAsStringSync('x');
      final out = Directory(p.join(tmp.path, 'out'))..createSync();

      final compressor = Compressor(sevenZip: SevenZip(missing));
      final job = CompressionJob(
        filepath: src.path,
        outputDir: out.path,
        format: '7z',
      );
      expect(compressor.compress(job), isFalse);
      expect(job.status, 'Failed');
      expect(job.error, contains('7-Zip executable not found'));
    }, skip: !isPosix);

    test('locate() ignores a non-existent OPENROM_7Z and finds PATH 7z', () {
      final stub = _writeSevenZipStub(tmp, logPath: logPath, name: '7z');
      final dir = Directory(p.join(tmp.path, 'bin'))..createSync();
      File(p.join(dir.path, '7z')).writeAsStringSync(
        File(stub).readAsStringSync(),
      );
      Process.runSync('chmod', ['+x', p.join(dir.path, '7z')]);

      final logs = <String>[];
      final found = SevenZip.locate(
        environment: {
          'OPENROM_7Z': p.join(tmp.path, 'nope-7z'),
          'PATH': dir.path,
        },
        onLog: logs.add,
      );
      expect(found, p.join(dir.path, '7z'));
      expect(logs.join('\n'), contains('does not exist'));

      // An existing OPENROM_7Z wins.
      final found2 = SevenZip.locate(
        environment: {'OPENROM_7Z': stub, 'PATH': ''},
      );
      expect(found2, stub);
    }, skip: !isPosix);
  });

  // ── parseSevenZipListing unit tests ────────────────────────────────────
  group('parseSevenZipListing', () {
    test('parses a real 7-Zip 25.01 listing', () {
      final listing = parseSevenZipListing(_realListingSample);
      expect(listing.entries.map((e) => e.path), [
        'sub',
        'Pokémon (Europe).gba',
        'a.txt',
        'sub/b.bin',
      ]);
      expect(listing.entries.first.isDirectory, isTrue);
      expect(listing.entries[1].isDirectory, isFalse);
      expect(listing.entries[1].size, '1');
      expect(listing.headerEncrypted, isFalse);
    });

    test('ignores the header Path line before the separator', () {
      final listing = parseSevenZipListing(_realListingSample);
      expect(listing.entries.any((e) => e.path == 'sample.7z'), isFalse);
    });

    test('handles paths with spaces and unicode', () {
      const sample = '''
--
Path = x.7z
Type = 7z

----------
Path = Tony Hawk's Pro Skater 2 (USA) (Track 1).bin
Size = 10
Attributes = A -rw-r--r--

Path = Pokémon (Europe).gba
Size = 20
Attributes = A -rw-r--r--

''';
      final listing = parseSevenZipListing(sample);
      expect(listing.entries.map((e) => e.path), [
        "Tony Hawk's Pro Skater 2 (USA) (Track 1).bin",
        'Pokémon (Europe).gba',
      ]);
    });

    test('empty archive (header only) yields no entries', () {
      const sample = '''
--
Path = empty.7z
Type = 7z

----------
''';
      final listing = parseSevenZipListing(sample);
      expect(listing.entries, isEmpty);
      expect(listing.isEmpty, isTrue);
    });

    test('header-only output with no separator yields no entries', () {
      const sample = '''
7-Zip 25.01 (x64) : Copyright (c) 1999-2025 Igor Pavlov : 2025-08-03

Listing archive: empty.7z

--
Path = empty.7z
Type = 7z
''';
      expect(parseSevenZipListing(sample).entries, isEmpty);
    });

    test('detects header encryption', () {
      const sample = '''
--
Path = enc.7z
Type = 7z
Encrypted = +

----------
Path = secret.txt
Size = 5
Encrypted = +
Method = 7zAES

''';
      final listing = parseSevenZipListing(sample);
      expect(listing.headerEncrypted, isTrue);
      expect(listing.entries.single.isEncrypted, isTrue);
    });

    test('handles CRLF line endings', () {
      final sample = _realListingSample.replaceAll('\n', '\r\n');
      final listing = parseSevenZipListing(sample);
      expect(listing.entries.length, 4);
      expect(listing.entries[1].path, 'Pokémon (Europe).gba');
    });
  });

  // ── Group 2: real 7-Zip round-trip tests ───────────────────────────────
  final realExe = SevenZip.locate();
  final require7z = Platform.environment['OPENROM_REQUIRE_7Z'] == '1';
  final skipReal = realExe == null && !require7z;
  final realSkipReason =
      'no 7-Zip executable found (set OPENROM_REQUIRE_7Z=1 to force failure)';

  group('7z real round trip', () {
    late Directory tmp;
    late Compressor compressor;

    setUp(() {
      if (realExe == null) return;
      tmp = Directory.systemTemp.createTempSync('openrom_7z_real_');
      compressor = Compressor(sevenZip: SevenZip(realExe));
    });

    tearDown(() {
      try {
        if (realExe != null && tmp.existsSync()) {
          tmp.deleteSync(recursive: true);
        }
      } catch (_) {}
    });

    test('locate() finds a real 7-Zip on this host', () {
      expect(realExe, isNotNull,
          reason: 'OPENROM_REQUIRE_7Z=1 but no 7-Zip was found');
    }, skip: skipReal ? realSkipReason : null);

    for (final level in ['fast', 'normal', 'ultra']) {
      test('round trip ($level): bytes identical, ultra beats the source', () {
        final rnd =
            List<int>.generate(1024 * 1024, (i) => (i * 2654435761) & 0xFF);
        final zeros = List<int>.filled(1024 * 1024, 0);
        final src = File(p.join(tmp.path, 'blob.bin'))
          ..writeAsBytesSync([...rnd, ...zeros]);
        final srcSha = _sha256OfFile(src.path);

        final out = Directory(p.join(tmp.path, 'out'))..createSync();
        final job = CompressionJob(
          filepath: src.path,
          outputDir: out.path,
          format: '7z',
          level: level,
        );
        expect(compressor.compress(job), isTrue, reason: job.error);

        final archive = p.join(out.path, 'blob.bin.7z');
        expect(File(archive).existsSync(), isTrue);

        final back = Directory(p.join(tmp.path, 'back'))..createSync();
        final ex = CompressionJob(
          filepath: archive,
          outputDir: back.path,
          format: 'extract',
        );
        expect(compressor.extract(ex), isTrue, reason: ex.error);

        final extracted = p.join(back.path, 'blob.bin');
        expect(File(extracted).existsSync(), isTrue);
        expect(_sha256OfFile(extracted), srcSha);

        if (level == 'ultra') {
          expect(File(archive).lengthSync(), lessThan(src.lengthSync()));
        }
      }, skip: skipReal ? realSkipReason : null);
    }

    test('directory round trip with tricky names', () {
      final src = Directory(p.join(tmp.path, 'disc'))..createSync();
      Directory(p.join(src.path, 'nested', 'deeper'))
          .createSync(recursive: true);
      File(p.join(src.path, 'nested', 'deeper', 'empty.dat'))
          .writeAsStringSync('');
      Directory(p.join(src.path, 'emptydir')).createSync();
      File(p.join(src.path, "Tony Hawk's Pro Skater 2 (USA) (Track 1).bin"))
          .writeAsStringSync('track1');
      File(p.join(src.path, 'Pokémon (Europe).gba')).writeAsStringSync('poke');

      final out = Directory(p.join(tmp.path, 'out'))..createSync();
      final job = CompressionJob(
        filepath: src.path,
        outputDir: out.path,
        format: '7z',
      );
      expect(compressor.compress(job), isTrue, reason: job.error);

      final archive = p.join(out.path, 'disc.7z');
      final back = Directory(p.join(tmp.path, 'back'))..createSync();
      final ex = CompressionJob(
        filepath: archive,
        outputDir: back.path,
        format: 'extract',
      );
      expect(compressor.extract(ex), isTrue, reason: ex.error);

      // Entries are rooted at the folder name, matching the ZIP behaviour.
      final root = p.join(back.path, 'disc');
      expect(
        File(p.join(root, "Tony Hawk's Pro Skater 2 (USA) (Track 1).bin"))
            .readAsStringSync(),
        'track1',
      );
      expect(
        File(p.join(root, 'Pokémon (Europe).gba')).readAsStringSync(),
        'poke',
      );
      expect(
        File(p.join(root, 'nested', 'deeper', 'empty.dat')).existsSync(),
        isTrue,
      );
    }, skip: skipReal ? realSkipReason : null);

    test('source untouched by default; deleteSource removes it on success', () {
      final src = File(p.join(tmp.path, 'keep.bin'))..writeAsStringSync('data');
      final out = Directory(p.join(tmp.path, 'out'))..createSync();

      final job = CompressionJob(
        filepath: src.path,
        outputDir: out.path,
        format: '7z',
      );
      expect(compressor.compress(job), isTrue, reason: job.error);
      expect(src.existsSync(), isTrue);

      final src2 = File(p.join(tmp.path, 'gone.bin'))
        ..writeAsStringSync('data');
      final job2 = CompressionJob(
        filepath: src2.path,
        outputDir: out.path,
        format: '7z',
        deleteSource: true,
      );
      expect(compressor.compress(job2), isTrue, reason: job2.error);
      expect(src2.existsSync(), isFalse);
    }, skip: skipReal ? realSkipReason : null);

    test('compressing an existing .7z reports Skipped (already compressed)',
        () {
      final src = File(p.join(tmp.path, 'already.7z'))
        ..writeAsStringSync('not really an archive');
      final out = Directory(p.join(tmp.path, 'out'))..createSync();
      final job = CompressionJob(
        filepath: src.path,
        outputDir: out.path,
        format: '7z',
      );
      expect(compressor.compress(job), isTrue);
      expect(job.status, 'Done');
      expect(job.error, contains('already compressed'));
    }, skip: skipReal ? realSkipReason : null);

    test('corrupted archive fails with no partial files left behind', () {
      final src = File(p.join(tmp.path, 'blob.bin'))
        ..writeAsBytesSync(List<int>.generate(4096, (i) => i & 0xFF));
      final out = Directory(p.join(tmp.path, 'out'))..createSync();
      final job = CompressionJob(
        filepath: src.path,
        outputDir: out.path,
        format: '7z',
      );
      expect(compressor.compress(job), isTrue, reason: job.error);

      final archive = File(p.join(out.path, 'blob.bin.7z'));
      final bytes = archive.readAsBytesSync();
      archive.writeAsBytesSync(bytes.sublist(0, bytes.length ~/ 2));

      final back = Directory(p.join(tmp.path, 'back'))..createSync();
      final ex = CompressionJob(
        filepath: archive.path,
        outputDir: back.path,
        format: 'extract',
      );
      expect(compressor.extract(ex), isFalse);
      expect(ex.status, 'Failed');
      expect(back.listSync(), isEmpty);
    }, skip: skipReal ? realSkipReason : null);

    test('encrypted archive fails fast with the encrypted message', () {
      final src = Directory(p.join(tmp.path, 'enc'))..createSync();
      final f = File(p.join(src.path, 'secret.txt'))..writeAsStringSync('hi');
      final archive = p.join(tmp.path, 'enc.7z');
      final r = Process.runSync(
        realExe!,
        [
          'a',
          '-t7z',
          '-pSECRET',
          '-mhe=on',
          '-y',
          '-bd',
          '--',
          archive,
          'secret.txt'
        ],
        workingDirectory: src.path,
      );
      expect(r.exitCode, 0, reason: '${r.stdout}\n${r.stderr}');
      expect(File(archive).existsSync(), isTrue);

      final back = Directory(p.join(tmp.path, 'back'))..createSync();
      final ex = CompressionJob(
        filepath: archive,
        outputDir: back.path,
        format: 'extract',
      );
      final sw = Stopwatch()..start();
      expect(compressor.extract(ex), isFalse);
      sw.stop();
      expect(ex.error, contains('encrypted archives are not supported'));
      expect(back.listSync(), isEmpty);
      expect(sw.elapsed.inSeconds, lessThan(30));
      // `f` exists so the fixture is real, not vacuous.
      expect(f.existsSync(), isTrue);
    },
        skip: skipReal ? realSkipReason : null,
        timeout: const Timeout(Duration(seconds: 60)));

    test('existing output .7z is replaced, not appended', () {
      final src = Directory(p.join(tmp.path, 'src'))..createSync();
      File(p.join(src.path, 'game.bin')).writeAsStringSync('payload');
      final out = Directory(p.join(tmp.path, 'out'))..createSync();

      // Seed the final archive with a decoy entry.
      final decoyDir = Directory(p.join(tmp.path, 'decoy'))..createSync();
      File(p.join(decoyDir.path, 'decoy.txt')).writeAsStringSync('decoy');
      final finalArchive = p.join(out.path, 'game.bin.7z');
      final r = Process.runSync(
        realExe!,
        ['a', '-t7z', '-y', '-bd', '--', finalArchive, 'decoy.txt'],
        workingDirectory: decoyDir.path,
      );
      expect(r.exitCode, 0);

      final job = CompressionJob(
        filepath: p.join(src.path, 'game.bin'),
        outputDir: out.path,
        format: '7z',
      );
      expect(compressor.compress(job), isTrue, reason: job.error);

      final listing = Process.runSync(
        realExe,
        ['l', '-slt', '-y', '--', finalArchive],
      );
      final entries = parseSevenZipListing('${listing.stdout}').entries;
      expect(entries.map((e) => e.path), ['game.bin']);
    }, skip: skipReal ? realSkipReason : null);
  });
}
