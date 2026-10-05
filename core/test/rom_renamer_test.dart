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
}
