import 'package:openrom_core/openrom_core.dart';
import 'package:test/test.dart';

void main() {
  group('Argument Tokenization & Quote Stripping', () {
    test('cleanCommandArgs strips literal surrounding double quotes', () {
      final input = [
        'chdman',
        'createcd',
        '-i',
        '"/path/to/my game.cue"',
        '-o',
        '"/path/to/my game.chd"'
      ];
      final cleaned = cleanCommandArgs(input);
      expect(
          cleaned,
          equals([
            'chdman',
            'createcd',
            '-i',
            '/path/to/my game.cue',
            '-o',
            '/path/to/my game.chd'
          ]));
    });

    test('cleanCommandArgs strips literal surrounding single quotes', () {
      final input = [
        'maxcso',
        "'/path/to/rom.iso'",
        '-o',
        "'/path/to/rom.cso'"
      ];
      final cleaned = cleanCommandArgs(input);
      expect(cleaned,
          equals(['maxcso', '/path/to/rom.iso', '-o', '/path/to/rom.cso']));
    });

    test(
        'splitCommandArgs tokenizes command string with quotes and spaces correctly',
        () {
      const cmdStr =
          'chdman createcd -i "C:\\My Games\\game.cue" -o "C:\\My Games\\game.chd" --compression cdlz,cdfl';
      final tokens = splitCommandArgs(cmdStr);
      expect(
        tokens,
        equals([
          'chdman',
          'createcd',
          '-i',
          'C:\\My Games\\game.cue',
          '-o',
          'C:\\My Games\\game.chd',
          '--compression',
          'cdlz,cdfl',
        ]),
      );
    });

    test('splitCommandArgs handles mixed quotes and unquoted arguments', () {
      const cmdStr = "nodtool convert 'my disc/game.gcz' \"out dir/game.iso\"";
      final tokens = splitCommandArgs(cmdStr);
      expect(
          tokens,
          equals(
              ['nodtool', 'convert', 'my disc/game.gcz', 'out dir/game.iso']));
    });
  });
}
