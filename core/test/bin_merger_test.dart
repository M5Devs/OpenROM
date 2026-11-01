// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:convert';
import 'dart:io';

import 'package:openrom_core/openrom_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Writes a CUE file, optionally with CRLF line endings and a UTF-8 BOM.
String _writeCue(
  Directory dir,
  String name,
  String content, {
  bool crlf = false,
  bool bom = false,
}) {
  final body = crlf ? content.replaceAll('\n', '\r\n') : content;
  final bytes = <int>[
    if (bom) ...const [0xEF, 0xBB, 0xBF],
    ...utf8.encode(body),
  ];
  final path = p.join(dir.path, name);
  File(path).writeAsBytesSync(bytes);
  return path;
}

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('openrom_cue_test_');
  });

  tearDown(() {
    try {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('parseCue FILE lines', () {
    test('parses an apostrophe in a quoted name', () {
      final cue = _writeCue(tmp, 'a.cue', '''
FILE "Tony Hawk's Pro Skater 2 (USA) (Track 1).bin" BINARY
  TRACK 01 MODE1/2352
    INDEX 01 00:00:00
''');
      final tracks = parseCue(cue);
      expect(tracks.single.relFile,
          "Tony Hawk's Pro Skater 2 (USA) (Track 1).bin");
    });

    test('parses parentheses and unicode', () {
      final cue = _writeCue(tmp, 'b.cue', '''
FILE "Pokémon (Europe) (Track 1).bin" BINARY
  TRACK 01 MODE1/2352
    INDEX 01 00:00:00
''');
      expect(parseCue(cue).single.relFile, 'Pokémon (Europe) (Track 1).bin');
    });

    test('accepts lowercase "file"', () {
      final cue = _writeCue(tmp, 'c.cue', '''
file "lower.bin" BINARY
  TRACK 01 MODE1/2352
    INDEX 01 00:00:00
''');
      expect(parseCue(cue).single.relFile, 'lower.bin');
    });

    test('parses single-quoted names', () {
      final cue = _writeCue(tmp, 'd.cue', '''
FILE 'single quoted name.bin' BINARY
  TRACK 01 MODE1/2352
    INDEX 01 00:00:00
''');
      expect(parseCue(cue).single.relFile, 'single quoted name.bin');
    });

    test('parses unquoted names', () {
      final cue = _writeCue(tmp, 'e.cue', '''
FILE bare-name.bin BINARY
  TRACK 01 MODE1/2352
    INDEX 01 00:00:00
''');
      expect(parseCue(cue).single.relFile, 'bare-name.bin');
    });

    test("parses a name containing both ' and spaces", () {
      final cue = _writeCue(tmp, 'f.cue', '''
FILE "Bob's 'great' game.bin" BINARY
  TRACK 01 MODE1/2352
    INDEX 01 00:00:00
''');
      expect(parseCue(cue).single.relFile, "Bob's 'great' game.bin");
    });

    test('handles CRLF line endings', () {
      final cue = _writeCue(
          tmp,
          'g.cue',
          '''
FILE "crlf name.bin" BINARY
  TRACK 01 MODE1/2352
    INDEX 01 00:00:00
''',
          crlf: true);
      expect(parseCue(cue).single.relFile, 'crlf name.bin');
    });

    test('handles a UTF-8 BOM at the start of the file', () {
      final cue = _writeCue(
          tmp,
          'h.cue',
          '''
FILE "bom name.bin" BINARY
  TRACK 01 MODE1/2352
    INDEX 01 00:00:00
''',
          bom: true);
      final tracks = parseCue(cue);
      expect(tracks.single.relFile, 'bom name.bin');
    });

    test('rejects a non-BINARY file type with a clear error', () {
      final cue = _writeCue(tmp, 'i.cue', '''
FILE "audio.wav" WAVE
  TRACK 01 AUDIO
    INDEX 01 00:00:00
''');
      expect(
        () => parseCue(cue),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('WAVE'),
          ),
        ),
      );
    });
  });

  group('mergeBins round trip with tricky names', () {
    test('concatenates bytes and computes offsets', () {
      // 2352-byte sectors so sector arithmetic is exact.
      final a = List<int>.generate(2352, (i) => i & 0xFF);
      final b = List<int>.generate(2352 * 2, (i) => (i * 7) & 0xFF);
      File(p.join(tmp.path, "Tony Hawk's Pro Skater 2 (USA) (Track 1).bin"))
          .writeAsBytesSync(a);
      File(p.join(tmp.path, 'Pokémon (Europe) (Track 2).bin'))
          .writeAsBytesSync(b);

      final cue = _writeCue(tmp, 'disc.cue', '''
FILE "Tony Hawk's Pro Skater 2 (USA) (Track 1).bin" BINARY
  TRACK 01 MODE1/2352
    INDEX 01 00:00:00
FILE "Pokémon (Europe) (Track 2).bin" BINARY
  TRACK 02 MODE1/2352
    INDEX 01 00:00:00
''');

      final out = Directory(p.join(tmp.path, 'out'))..createSync();
      final result = mergeBins(cue, outputDir: out.path);

      // Merged BIN is the exact concatenation of the two tracks.
      final merged = File(result.mergedBinPath).readAsBytesSync();
      expect(merged.length, a.length + b.length);
      expect(merged.sublist(0, a.length), a);
      expect(merged.sublist(a.length), b);

      final mergedCue = File(result.mergedCuePath).readAsStringSync();
      expect(mergedCue, contains('FILE "disc_merged.bin" BINARY'));
      expect(mergedCue, contains('TRACK 01 MODE1/2352'));
      expect(mergedCue, contains('INDEX 01 00:00:00'));
      expect(mergedCue, contains('TRACK 02 MODE1/2352'));
      // Track 2 starts after track 1's 2352-byte sector = 00:00:01.
      expect(mergedCue, contains('INDEX 01 00:00:01'));
    });
  });
}
