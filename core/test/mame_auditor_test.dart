// OpenROM — MAME / Arcade Auditor Tests
// M5 Dev | GPL v3
//
// These tests build realistic synthetic arcade sets on disk (real MAME ROM
// filenames and real CRC-32s for the bytes we write) and drive the auditor
// through the same scenarios a real collection produces: a standalone set, a
// Neo-Geo game that needs the `neogeo` BIOS, and a CHD-based game.

import 'dart:io';

import 'package:archive/archive.dart';
import 'package:openrom_core/openrom_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// CRC-32 (IEEE) of [bytes] as 8 lower-case hex characters. Mirrors what a
/// ZIP central directory stores and what the DAT declares.
String _crc32Hex(List<int> bytes) {
  final table = _crcTable;
  var c = 0xFFFFFFFF;
  for (final b in bytes) {
    c = table[(c ^ b) & 0xFF] ^ (c >> 8);
  }
  final v = (c ^ 0xFFFFFFFF) & 0xFFFFFFFF;
  return v.toRadixString(16).toLowerCase().padLeft(8, '0');
}

final List<int> _crcTable = () {
  final t = List<int>.filled(256, 0);
  for (var i = 0; i < 256; i++) {
    var c = i;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
    }
    t[i] = c;
  }
  return t;
}();

/// Deterministic pseudo-random bytes so a "ROM" has a stable CRC across runs.
List<int> _romBytes(int size, int seed) {
  final out = List<int>.filled(size, 0);
  var x = seed * 2654435761 + 1;
  for (var i = 0; i < size; i++) {
    x = (x * 1103515245 + 12345) & 0x7FFFFFFF;
    out[i] = (x >> 16) & 0xFF;
  }
  return out;
}

/// A synthetic ROM definition: filename, content, and the CRC of that content.
class _SyntheticRom {
  final String name;
  final List<int> content;
  _SyntheticRom(this.name, this.content);

  int get size => content.length;
  String get crc => _crc32Hex(content);
}

/// Writes a real ZIP archive containing [roms] (name -> bytes) to [path].
void _writeZip(String path, Map<String, List<int>> roms) {
  final archive = Archive();
  roms.forEach((name, bytes) {
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  });
  final encoded = ZipEncoder().encode(archive)!;
  File(path).writeAsBytesSync(encoded);
}

void main() {
  late Directory tmp;
  late String folder;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('mame_audit_');
    folder = p.join(tmp.path, 'roms');
    Directory(folder).createSync(recursive: true);
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  group('Streaming MAME XML parser', () {
    test('parses machine metadata, description, roms and disks', () async {
      final datPath = p.join(tmp.path, 'mame.xml');
      File(datPath).writeAsStringSync('''
<?xml version="1.0"?>
<mame build="0.250">
  <machine name="pacman" sourcefile="pacman.cpp">
    <description>Pac-Man (Midway)</description>
    <rom name="pacman.6e" size="4096" crc="c1e6ab10" sha1="aaaa"/>
    <rom name="pacman.6f" size="4096" crc="1a6ea878" sha1="bbbb"/>
  </machine>
  <machine name="kinst" sourcefile="kinst.cpp">
    <description>Killer Instinct (v1.5)</description>
    <rom name="ki.rom" size="1024" crc="deadbeef"/>
    <disk name="kinst" sha1="cccc"/>
  </machine>
  <machine name="neogeo" isbios="yes">
    <description>Neo-Geo</description>
    <rom name="bios.rom" size="128" crc="abcd1234"/>
  </machine>
</mame>
''');

      final dat = await parseMameDat(datPath);
      expect(dat.machines.length, 3);

      final pacman = dat.machines['pacman']!;
      expect(pacman.description, 'Pac-Man (Midway)');
      expect(pacman.roms.length, 2);
      expect(pacman.roms.first.name, 'pacman.6e');
      expect(pacman.roms.first.size, 4096);
      expect(pacman.roms.first.crc, 'c1e6ab10');

      final kinst = dat.machines['kinst']!;
      expect(kinst.disks.length, 1);
      expect(kinst.disks.first.name, 'kinst');

      expect(dat.machines['neogeo']!.isBios, isTrue);
    });

    test('parses Logiqx DAT <game> elements and clone/romof attrs', () async {
      final datPath = p.join(tmp.path, 'neogeo.dat');
      File(datPath).writeAsStringSync('''
<?xml version="1.0"?>
<datafile>
  <header>
    <name>SNK - Neo Geo</name>
    <description>SNK - Neo Geo</description>
    <version>2024</version>
  </header>
  <game name="mslug" romof="neogeo">
    <description>Metal Slug - Super Vehicle-001</description>
    <rom name="201-p1.p1" size="2097152" crc="08d8daa5"/>
    <rom name="201-c1.c1" size="8388608" crc="5a79c34e"/>
  </game>
  <game name="mslug2" cloneof="mslug" romof="neogeo">
    <description>Metal Slug 2</description>
    <rom name="2-p1.p1" size="2097152" crc="11112222"/>
    <rom name="201-c1.c1" size="8388608" crc="5a79c34e" merge="201-c1.c1"/>
  </game>
</datafile>
''');

      final dat = await parseMameDat(datPath);
      expect(dat.name, 'SNK - Neo Geo');
      expect(dat.version, '2024');
      expect(dat.machines.length, 2);

      final mslug = dat.machines['mslug']!;
      expect(mslug.romOf, 'neogeo');
      expect(mslug.cloneOf, isNull);
      expect(mslug.description, 'Metal Slug - Super Vehicle-001');

      final mslug2 = dat.machines['mslug2']!;
      expect(mslug2.cloneOf, 'mslug');
      expect(mslug2.isClone, isTrue);
      expect(mslug2.roms[1].merge, '201-c1.c1');
    });
  });

  group('ZIP central-directory scanning', () {
    test('reads entry names, sizes and CRCs without extracting', () {
      final rom = _SyntheticRom('pacman.6e', _romBytes(4096, 7));
      final zipPath = p.join(folder, 'pacman.zip');
      _writeZip(zipPath, {rom.name: rom.content});

      final entries = readZipEntries(zipPath);
      expect(entries.length, 1);
      expect(entries.first.name, 'pacman.6e');
      expect(entries.first.size, 4096);
      expect(entries.first.crc, rom.crc);
    });
  });

  group('Pac-Man (pacman) — standalone set', () {
    test('complete when all chips match', () async {
      final roms = {
        'pacman.6e': _romBytes(4096, 1),
        'pacman.6f': _romBytes(4096, 2),
        'pacman.6h': _romBytes(4096, 3),
        'pacman.6j': _romBytes(4096, 4),
      };
      _writeZip(p.join(folder, 'pacman.zip'), roms);

      final datPath = p.join(tmp.path, 'mame.xml');
      File(datPath).writeAsStringSync('''
<mame>
  <machine name="pacman">
    <description>Pac-Man (Midway)</description>
    <rom name="pacman.6e" size="4096" crc="${_crc32Hex(roms['pacman.6e']!)}"/>
    <rom name="pacman.6f" size="4096" crc="${_crc32Hex(roms['pacman.6f']!)}"/>
    <rom name="pacman.6h" size="4096" crc="${_crc32Hex(roms['pacman.6h']!)}"/>
    <rom name="pacman.6j" size="4096" crc="${_crc32Hex(roms['pacman.6j']!)}"/>
  </machine>
</mame>
''');

      final report =
          await auditMameCollection(datPath: datPath, folder: folder);
      expect(report.total, 1);
      final result = report.results.single;
      expect(result.status, MameAuditStatus.complete);
      expect(result.romsPresent, 4);
      expect(result.missingRoms, isEmpty);
      expect(report.healthPercent, 100.0);
    });

    test('incomplete when a chip is missing from the zip', () async {
      final roms = {
        'pacman.6e': _romBytes(4096, 1),
        'pacman.6f': _romBytes(4096, 2),
      };
      _writeZip(p.join(folder, 'pacman.zip'), roms);

      final datPath = p.join(tmp.path, 'mame.xml');
      File(datPath).writeAsStringSync('''
<mame>
  <machine name="pacman">
    <description>Pac-Man (Midway)</description>
    <rom name="pacman.6e" size="4096" crc="${_crc32Hex(roms['pacman.6e']!)}"/>
    <rom name="pacman.6f" size="4096" crc="${_crc32Hex(roms['pacman.6f']!)}"/>
    <rom name="pacman.6h" size="4096" crc="11111111"/>
  </machine>
</mame>
''');

      final report =
          await auditMameCollection(datPath: datPath, folder: folder);
      final result = report.results.single;
      expect(result.status, MameAuditStatus.incomplete);
      expect(result.missingRoms.length, 1);
      expect(result.missingRoms.single.name, 'pacman.6h');
      expect(result.missingRoms.single.expectedSize, 4096);
    });

    test('flags a CRC mismatch distinctly from a missing chip', () async {
      // Write a chip whose content does not match the declared CRC.
      _writeZip(p.join(folder, 'pacman.zip'), {
        'pacman.6e': _romBytes(4096, 1),
      });

      final datPath = p.join(tmp.path, 'mame.xml');
      File(datPath).writeAsStringSync('''
<mame>
  <machine name="pacman">
    <description>Pac-Man (Midway)</description>
    <rom name="pacman.6e" size="4096" crc="00000000"/>
  </machine>
</mame>
''');

      final report =
          await auditMameCollection(datPath: datPath, folder: folder);
      final result = report.results.single;
      expect(result.status, MameAuditStatus.incomplete);
      expect(result.missingRoms.single.reason, 'crc_mismatch');
      expect(
          result.missingRoms.single.actualCrc, _crc32Hex(_romBytes(4096, 1)));
    });
  });

  group('Metal Slug (mslug) — Neo-Geo BIOS dependency', () {
    late String datPath;

    setUp(() async {
      final mslugP1 = _romBytes(2 * 1024 * 1024, 11);
      final mslugC1 = _romBytes(4 * 1024 * 1024, 12);
      final bios = _romBytes(128 * 1024, 99);

      datPath = p.join(tmp.path, 'neogeo.xml');
      File(datPath).writeAsStringSync('''
<mame>
  <machine name="neogeo" isbios="yes">
    <description>Neo-Geo</description>
    <rom name="sp-s2.sp1" size="131072" crc="${_crc32Hex(bios)}"/>
  </machine>
  <machine name="mslug" romof="neogeo">
    <description>Metal Slug - Super Vehicle-001</description>
    <rom name="201-p1.p1" size="2097152" crc="${_crc32Hex(mslugP1)}"/>
    <rom name="201-c1.c1" size="4194304" crc="${_crc32Hex(mslugC1)}"/>
  </machine>
</mame>
''');

      _writeZip(p.join(folder, 'mslug.zip'), {
        '201-p1.p1': mslugP1,
        '201-c1.c1': mslugC1,
      });
    });

    test('case A: mslug.zip alone -> Missing BIOS (neogeo.zip)', () async {
      final report =
          await auditMameCollection(datPath: datPath, folder: folder);
      final mslug = report.results.firstWhere((r) => r.name == 'mslug');
      expect(mslug.status, MameAuditStatus.missingBios);
      expect(mslug.missingBios, contains('neogeo'));
      expect(mslug.romsPresent, 2);
    });

    test('case B: mslug.zip + neogeo.zip -> Complete (Playable)', () async {
      _writeZip(p.join(folder, 'neogeo.zip'), {
        'sp-s2.sp1': _romBytes(128 * 1024, 99),
      });

      final report =
          await auditMameCollection(datPath: datPath, folder: folder);
      final mslug = report.results.firstWhere((r) => r.name == 'mslug');
      expect(mslug.status, MameAuditStatus.complete);
      expect(mslug.missingBios, isEmpty);
    });

    test('neogeo.zip present but missing the BIOS chip -> Missing BIOS',
        () async {
      // Wrong content for the BIOS chip -> set is present but incomplete.
      _writeZip(p.join(folder, 'neogeo.zip'), {
        'sp-s2.sp1': _romBytes(128 * 1024, 12345),
      });

      final report =
          await auditMameCollection(datPath: datPath, folder: folder);
      final mslug = report.results.firstWhere((r) => r.name == 'mslug');
      expect(mslug.status, MameAuditStatus.missingBios);
    });
  });

  group('Clone / parent dependency (split set)', () {
    test('clone without its parent zip -> Missing Parent', () async {
      final parentP1 = _romBytes(1024, 21);
      final cloneP1 = _romBytes(1024, 22);

      final datPath = p.join(tmp.path, 'clones.xml');
      File(datPath).writeAsStringSync('''
<mame>
  <machine name="parent">
    <description>Parent Game</description>
    <rom name="p1.bin" size="1024" crc="${_crc32Hex(parentP1)}"/>
  </machine>
  <machine name="clone" cloneof="parent" romof="parent">
    <description>Clone Game</description>
    <rom name="c1.bin" size="1024" crc="${_crc32Hex(cloneP1)}"/>
    <rom name="p1.bin" size="1024" crc="${_crc32Hex(parentP1)}" merge="p1.bin"/>
  </machine>
</mame>
''');

      _writeZip(p.join(folder, 'clone.zip'), {'c1.bin': cloneP1});

      final report =
          await auditMameCollection(datPath: datPath, folder: folder);
      final clone = report.results.firstWhere((r) => r.name == 'clone');
      expect(clone.status, MameAuditStatus.missingParent);
      expect(clone.missingParents, contains('parent'));
      // The merged ROM is the parent's, so the clone's own chip matched.
      expect(clone.romsPresent, 1);
    });

    test('clone + parent zip -> Complete', () async {
      final parentP1 = _romBytes(1024, 21);
      final cloneP1 = _romBytes(1024, 22);

      final datPath = p.join(tmp.path, 'clones.xml');
      File(datPath).writeAsStringSync('''
<mame>
  <machine name="parent">
    <description>Parent Game</description>
    <rom name="p1.bin" size="1024" crc="${_crc32Hex(parentP1)}"/>
  </machine>
  <machine name="clone" cloneof="parent" romof="parent">
    <description>Clone Game</description>
    <rom name="c1.bin" size="1024" crc="${_crc32Hex(cloneP1)}"/>
    <rom name="p1.bin" size="1024" crc="${_crc32Hex(parentP1)}" merge="p1.bin"/>
  </machine>
</mame>
''');

      _writeZip(p.join(folder, 'clone.zip'), {'c1.bin': cloneP1});
      _writeZip(p.join(folder, 'parent.zip'), {'p1.bin': parentP1});

      final report =
          await auditMameCollection(datPath: datPath, folder: folder);
      final clone = report.results.firstWhere((r) => r.name == 'clone');
      expect(clone.status, MameAuditStatus.complete);
    });
  });

  group('Killer Instinct (kinst) — arcade CHD', () {
    late String datPath;

    setUp(() async {
      final rom = _romBytes(512 * 1024, 31);
      datPath = p.join(tmp.path, 'kinst.xml');
      File(datPath).writeAsStringSync('''
<mame>
  <machine name="kinst">
    <description>Killer Instinct (v1.5)</description>
    <rom name="ki_rom.bin" size="524288" crc="${_crc32Hex(rom)}"/>
    <disk name="kinst" sha1="0a1b2c3d"/>
  </machine>
</mame>
''');
      _writeZip(p.join(folder, 'kinst.zip'), {'ki_rom.bin': rom});
    });

    test('case A: kinst.zip without CHD -> Missing CHD (kinst.chd)', () async {
      final report =
          await auditMameCollection(datPath: datPath, folder: folder);
      final kinst = report.results.single;
      expect(kinst.status, MameAuditStatus.missingChd);
      expect(kinst.missingDisks.single.name, 'kinst.chd');
      expect(kinst.romsPresent, 1);
    });

    test('case B: kinst.zip + dummy kinst.chd -> Complete (Playable)',
        () async {
      // A dummy CHD beside the zip: existence is all the auditor checks.
      File(p.join(folder, 'kinst.chd')).writeAsBytesSync(
        List<int>.filled(256, 0),
      );

      final report =
          await auditMameCollection(datPath: datPath, folder: folder);
      final kinst = report.results.single;
      expect(kinst.status, MameAuditStatus.complete);
      expect(kinst.disksPresent, 1);
      expect(kinst.missingDisks, isEmpty);
    });

    test('CHD in a <machine>/ subfolder is detected', () async {
      final sub = Directory(p.join(folder, 'kinst'))..createSync();
      File(p.join(sub.path, 'kinst.chd')).writeAsBytesSync(
        List<int>.filled(256, 0),
      );

      final report =
          await auditMameCollection(datPath: datPath, folder: folder);
      expect(report.results.single.status, MameAuditStatus.complete);
    });
  });

  group('Aggregate report and JSON shape', () {
    test('computes health percentage and per-status counts', () async {
      final pac = _romBytes(1024, 41);
      final mslug = _romBytes(1024, 42);

      final datPath = p.join(tmp.path, 'mixed.xml');
      File(datPath).writeAsStringSync('''
<mame>
  <machine name="pacman">
    <description>Pac-Man (Midway)</description>
    <rom name="a.bin" size="1024" crc="${_crc32Hex(pac)}"/>
  </machine>
  <machine name="mslug" romof="neogeo">
    <description>Metal Slug</description>
    <rom name="b.bin" size="1024" crc="${_crc32Hex(mslug)}"/>
  </machine>
  <machine name="neogeo" isbios="yes">
    <description>Neo-Geo</description>
    <rom name="bios.bin" size="128" crc="deadbeef"/>
  </machine>
</mame>
''');

      _writeZip(p.join(folder, 'pacman.zip'), {'a.bin': pac});
      _writeZip(p.join(folder, 'mslug.zip'), {'b.bin': mslug});

      final report =
          await auditMameCollection(datPath: datPath, folder: folder);

      // The BIOS set is skipped from user-facing totals.
      expect(report.total, 2);
      expect(report.skippedDevices, 1);
      expect(report.completeCount, 1);
      expect(report.missingBiosCount, 1);
      expect(report.healthPercent, 50.0);

      final json = report.toJson();
      expect(json['total_games'], 2);
      expect(json['complete'], 1);
      expect(json['missing_bios'], 1);
      expect(json['health_percent'], 50.0);
      expect((json['games'] as List).length, 2);

      final mslugJson = (json['games'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((g) => g['name'] == 'mslug');
      expect(mslugJson['status'], 'missing_bios');
      expect(mslugJson['missing_bios'], contains('neogeo'));
    });

    test('includeBiosSets reports BIOS sets too', () async {
      final bios = _romBytes(128, 51);
      final datPath = p.join(tmp.path, 'bios.xml');
      File(datPath).writeAsStringSync('''
<mame>
  <machine name="neogeo" isbios="yes">
    <description>Neo-Geo</description>
    <rom name="bios.bin" size="128" crc="${_crc32Hex(bios)}"/>
  </machine>
</mame>
''');
      _writeZip(p.join(folder, 'neogeo.zip'), {'bios.bin': bios});

      final report = await auditMameCollection(
        datPath: datPath,
        folder: folder,
        options: const MameAuditOptions(includeBiosSets: true),
      );
      expect(report.total, 1);
      expect(report.completeCount, 1);
    });

    test('missing set reported when the zip is absent', () async {
      final datPath = p.join(tmp.path, 'absent.xml');
      File(datPath).writeAsStringSync('''
<mame>
  <machine name="ghost">
    <description>Ghost Game</description>
    <rom name="g.bin" size="64" crc="00112233"/>
  </machine>
</mame>
''');

      final report =
          await auditMameCollection(datPath: datPath, folder: folder);
      expect(report.results.single.status, MameAuditStatus.missing);
      expect(report.missingCount, 1);
    });
  });
}
