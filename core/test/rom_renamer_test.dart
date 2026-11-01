import 'dart:convert';
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

  test('streaming_dat_parsing_and_indexing', () async {
    final tmpDir = Directory.systemTemp.createTempSync('dat_test_');
    try {
      final datPath = p.join(tmpDir.path, 'sample.dat');
      final xmlContent = '''<?xml version="1.0"?>
<!DOCTYPE datafile PUBLIC "-//Logiqx//DTD DAT//EN" "http://www.logiqx.com/Dats/datafile.dtd">
<datafile>
	<header>
		<name>Nintendo - Game Boy</name>
		<description>Nintendo - Game Boy</description>
		<version>2023</version>
		<author>No-Intro</author>
		<url>http://www.no-intro.org</url>
	</header>
	<game name="Super Mario Land (World)">
		<description>Super Mario Land (World)</description>
		<rom name="Super Mario Land (World).gb" size="65536" crc="cbf43926" md5="11111111111111111111111111111111" sha1="2222222222222222222222222222222222222222"/>
	</game>
</datafile>''';
      File(datPath).writeAsStringSync(xmlContent);

      final index = await loadDatIndex(datPath);
      expect(index.containsKey('cbf43926'), isTrue);
      expect(index['cbf43926']!['name'], equals('Super Mario Land (World)'));
      expect(index['cbf43926']!['rom_name'],
          equals('Super Mario Land (World).gb'));

      // Test importDat
      final imported = await importDat(datPath);
      expect(imported['name'], equals('Nintendo - Game Boy'));
      expect(imported['source'], equals('No-Intro'));
      expect(imported['game_count'], equals(1));
    } finally {
      tmpDir.deleteSync(recursive: true);
    }
  });

  test('scanFolder_consolidates_multi_dats_for_o1_lookup', () async {
    final tmpDir = Directory.systemTemp.createTempSync('multi_dat_test_');
    try {
      final dat1Path = p.join(tmpDir.path, 'gb.dat');
      final dat2Path = p.join(tmpDir.path, 'nes.dat');

      File(dat1Path).writeAsStringSync('''<?xml version="1.0"?>
<datafile>
	<header>
		<name>Nintendo - Game Boy</name>
		<url>http://www.no-intro.org</url>
	</header>
	<game name="Super Mario Land">
		<description>Super Mario Land</description>
		<rom name="Super Mario Land.gb" size="9" crc="cbf43926"/>
	</game>
</datafile>''');

      File(dat2Path).writeAsStringSync('''<?xml version="1.0"?>
<datafile>
	<header>
		<name>Nintendo - NES</name>
		<url>http://www.no-intro.org</url>
	</header>
	<game name="Super Mario Bros.">
		<description>Super Mario Bros.</description>
		<rom name="Super Mario Bros.nes" size="40960" crc="00000000"/>
	</game>
</datafile>''');

      final romDir = p.join(tmpDir.path, 'roms');
      Directory(romDir).createSync();
      final rom1Path = p.join(romDir, 'mario.gb');
      File(rom1Path).writeAsStringSync('123456789'); // crc = cbf43926

      final results = await scanFolder(romDir, [dat1Path, dat2Path]);
      expect(results.length, equals(1));
      expect(results.first.matched, isTrue);
      expect(results.first.canonicalName, equals('Super Mario Land'));
      expect(results.first.suggestedFilename, equals('Super Mario Land.gb'));
    } finally {
      tmpDir.deleteSync(recursive: true);
    }
  });
  test('composite_dat_lookup_prevents_crc32_collisions', () async {
    final tmpDir = Directory.systemTemp.createTempSync('collision_test_');
    try {
      final datPath = p.join(tmpDir.path, 'collision.dat');
      final xmlContent = '''<?xml version="1.0"?>
<datafile>
	<header>
		<name>Collision DAT</name>
		<url>http://www.no-intro.org</url>
	</header>
	<game name="Game A">
		<description>Game A</description>
		<rom name="Game A.gb" size="9" crc="cbf43926"/>
	</game>
	<game name="Game B Collision">
		<description>Game B Collision</description>
		<rom name="Game B.gb" size="100" crc="cbf43926"/>
	</game>
</datafile>''';
      File(datPath).writeAsStringSync(xmlContent);

      final romDir = p.join(tmpDir.path, 'roms');
      Directory(romDir).createSync();
      final romPath = p.join(romDir, 'sample.gb');
      File(romPath).writeAsStringSync('123456789');

      final results = await scanFolder(romDir, [datPath]);
      expect(results.length, equals(1));
      expect(results.first.matched, isTrue);
      expect(results.first.canonicalName, equals('Game A'));
      expect(results.first.suggestedFilename, equals('Game A.gb'));

      final mismatchPath = p.join(romDir, 'mismatch.gb');
      File(mismatchPath).writeAsBytesSync(List<int>.filled(50, 0x31));

      final mismatchResults = await scanFolder(romDir, [datPath]);
      final mismatchRes =
          mismatchResults.firstWhere((r) => r.filename == 'mismatch.gb');
      expect(mismatchRes.matched, isFalse);
    } finally {
      tmpDir.deleteSync(recursive: true);
    }
  });

  group('safeRomFilename', () {
    const fallback = 'fallback.bin';

    test('leaves ordinary names untouched', () {
      for (final name in [
        "Tony Hawk's Pro Skater 2 (USA).bin",
        'Pokémon (Europe).gba',
        'Game! & Co, Vol. 1 (Japan).sfc',
        'Game [!].nes',
      ]) {
        expect(safeRomFilename(name, fallback: fallback), name);
      }
    });

    test('replaces path separators and reserved characters', () {
      expect(safeRomFilename('a/b.bin', fallback: fallback), 'a_b.bin');
      expect(safeRomFilename(r'a\b.bin', fallback: fallback), 'a_b.bin');
      expect(safeRomFilename('a:b.bin', fallback: fallback), 'a_b.bin');
      expect(safeRomFilename('a*b.bin', fallback: fallback), 'a_b.bin');
      expect(safeRomFilename('a?b.bin', fallback: fallback), 'a_b.bin');
      expect(safeRomFilename('a"b.bin', fallback: fallback), 'a_b.bin');
      expect(safeRomFilename('a<b>.bin', fallback: fallback), 'a_b_.bin');
      expect(safeRomFilename('a|b.bin', fallback: fallback), 'a_b.bin');
    });

    test('strips control characters including NUL', () {
      expect(safeRomFilename('a\u0000b.bin', fallback: fallback), 'a_b.bin');
      expect(safeRomFilename('a\u007Fb.bin', fallback: fallback), 'a_b.bin');
      expect(safeRomFilename('a\tb.bin', fallback: fallback), 'a_b.bin');
    });

    test('defuses traversal names', () {
      expect(safeRomFilename('../evil.bin', fallback: fallback), '.._evil.bin');
      expect(
        safeRomFilename(r'..\evil.bin', fallback: fallback),
        '.._evil.bin',
      );
      expect(safeRomFilename(r'C:\x.bin', fallback: fallback), 'C__x.bin');
    });

    test('a name that is only dots becomes the fallback', () {
      expect(safeRomFilename('..', fallback: fallback), fallback);
      expect(safeRomFilename('.', fallback: fallback), fallback);
      expect(safeRomFilename('...', fallback: fallback), fallback);
    });

    test('trims leading/trailing spaces and trailing dots', () {
      expect(
          safeRomFilename('  spaced.bin  ', fallback: fallback), 'spaced.bin');
      expect(safeRomFilename('trailing...', fallback: fallback), 'trailing');
      expect(safeRomFilename('  x.bin.  ', fallback: fallback), 'x.bin');
    });

    test('prefixes Windows reserved device names', () {
      expect(safeRomFilename('CON.bin', fallback: fallback), '_CON.bin');
      expect(safeRomFilename('nul', fallback: fallback), '_nul');
      expect(safeRomFilename('com1.gba', fallback: fallback), '_com1.gba');
      expect(safeRomFilename('LPT9', fallback: fallback), '_LPT9');
      // Not a reserved name.
      expect(safeRomFilename('CONTENT.bin', fallback: fallback), 'CONTENT.bin');
    });

    test('caps length at 200 UTF-8 bytes, keeping the extension', () {
      final long = '${'a' * 300}.bin';
      final safe = safeRomFilename(long, fallback: fallback);
      expect(utf8.encode(safe).length, lessThanOrEqualTo(200));
      expect(safe.endsWith('.bin'), isTrue);
    });

    test('empty result falls back', () {
      expect(safeRomFilename('', fallback: fallback), fallback);
      expect(safeRomFilename('   ', fallback: fallback), fallback);
      // Separators are replaced, so "///" is a valid (if odd) name.
      expect(safeRomFilename('///', fallback: fallback), '___');
    });
  });

  group('renameRoms containment', () {
    test('a malicious DAT name cannot escape the folder', () {
      final tmpDir = Directory.systemTemp.createTempSync('rename_safety_');
      try {
        final romPath = p.join(tmpDir.path, 'evil.bin');
        File(romPath).writeAsStringSync('data');

        final scan = RomScanResult(
          filepath: romPath,
          filename: 'evil.bin',
          matched: true,
          romName: '../escaped.bin',
        );

        final results = renameRoms([scan], dryRun: false);
        expect(results.single.success, isTrue);
        // The file must stay inside the folder.
        expect(results.single.newPath, p.join(tmpDir.path, '.._escaped.bin'));
        expect(p.dirname(p.canonicalize(results.single.newPath)),
            p.canonicalize(tmpDir.path));
        expect(File(romPath).existsSync(), isFalse);
        expect(
            File(p.join(tmpDir.path, '.._escaped.bin')).existsSync(), isTrue);
        expect(File(p.join(tmpDir.path, '..', 'escaped.bin')).existsSync(),
            isFalse);
      } finally {
        tmpDir.deleteSync(recursive: true);
      }
    });
  });
}
