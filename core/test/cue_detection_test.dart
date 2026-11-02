import 'dart:io';
import 'dart:typed_data';

import 'package:openrom_core/openrom_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Builds a 2352-byte raw-sector disc image with [magic] written at [offset].
Uint8List _discImage(List<int> magic, {int offset = 0x1100, int sectors = 40}) {
  final bytes = Uint8List(2352 * sectors);
  bytes.setRange(offset, offset + magic.length, magic);
  return bytes;
}

void _writeCue(String cuePath, String binName) {
  File(cuePath).writeAsStringSync(
    'FILE "$binName" BINARY\n'
    '  TRACK 01 MODE1/2352\n'
    '    INDEX 01 00:00:00\n',
  );
}

void main() {
  late Directory tmpDir;

  setUp(() {
    tmpDir = Directory.systemTemp.createTempSync('cue_detection_test_');
  });

  tearDown(() {
    if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
  });

  test('cue_resolves_ps1_bin_magic', () {
    final binPath = p.join(tmpDir.path, 'Final Fantasy VII (Disc 1).bin');
    File(binPath).writeAsBytesSync(
      _discImage('PLAYSTATION'.codeUnits),
    );
    final cuePath = p.join(tmpDir.path, 'Final Fantasy VII (Disc 1).cue');
    _writeCue(cuePath, p.basename(binPath));

    final info = detectFile(cuePath);
    expect(info['format'], equals('CUE'));
    expect(info['platform'], equals('PS1'));
    expect(info['paired_bin'], equals(binPath));
  });

  test('cue_resolves_dreamcast_bin_magic', () {
    final binPath = p.join(tmpDir.path, 'sonic.bin');
    File(binPath).writeAsBytesSync(
      _discImage('SEGA SEGAKATANA'.codeUnits),
    );
    final cuePath = p.join(tmpDir.path, 'sonic.cue');
    _writeCue(cuePath, p.basename(binPath));

    final info = detectFile(cuePath);
    expect(info['format'], equals('CUE'));
    expect(info['platform'], equals('Dreamcast'));
  });

  test('cue_resolves_saturn_bin_magic', () {
    final binPath = p.join(tmpDir.path, 'nights.bin');
    File(binPath).writeAsBytesSync(
      _discImage('SEGA SEGASATURN'.codeUnits, offset: 0x10),
    );
    final cuePath = p.join(tmpDir.path, 'nights.cue');
    _writeCue(cuePath, p.basename(binPath));

    final info = detectFile(cuePath);
    expect(info['platform'], equals('Saturn'));
  });

  test('cue_handles_apostrophes_spaces_and_unquoted_names', () {
    // Tony Hawk's Pro Skater.bin — apostrophe + spaces inside the FILE entry.
    final binPath = p.join(tmpDir.path, "Tony Hawk's Pro Skater.bin");
    File(binPath).writeAsBytesSync(
      _discImage('PLAYSTATION'.codeUnits),
    );
    final cuePath = p.join(tmpDir.path, "Tony Hawk's Pro Skater.cue");
    _writeCue(cuePath, p.basename(binPath));

    final info = detectFile(cuePath);
    expect(info['platform'], equals('PS1'));

    // Same again but with the filename left unquoted in the CUE sheet.
    final binPath2 = p.join(tmpDir.path, 'Crash Bandicoot.bin');
    File(binPath2).writeAsBytesSync(
      _discImage('PLAYSTATION'.codeUnits),
    );
    final cuePath2 = p.join(tmpDir.path, 'unquoted.cue');
    File(cuePath2).writeAsStringSync(
      'FILE Crash Bandicoot.bin BINARY\n'
      '  TRACK 01 MODE1/2352\n'
      '    INDEX 01 00:00:00\n',
    );

    final info2 = detectFile(cuePath2);
    expect(info2['platform'], equals('PS1'));
  });

  test('cue_resolves_bin_in_sibling_directory_relative_to_cue', () {
    final subDir = Directory(p.join(tmpDir.path, 'disc'))..createSync();
    final binPath = p.join(subDir.path, 'game.bin');
    File(binPath).writeAsBytesSync(
      _discImage('SEGA SEGAKATANA'.codeUnits),
    );
    final cuePath = p.join(tmpDir.path, 'game.cue');
    _writeCue(cuePath, 'disc/game.bin');

    final info = detectFile(cuePath);
    expect(info['platform'], equals('Dreamcast'));
  });

  test('cue_with_missing_bin_falls_back_without_throwing', () {
    final cuePath = p.join(tmpDir.path, 'missing.cue');
    _writeCue(cuePath, 'does_not_exist.bin');

    final info = detectFile(cuePath);
    expect(info.containsKey('error'), isFalse);
    expect(info['format'], equals('CUE'));
    expect(info['platform'], equals('UNKNOWN'));
  });

  test('cue_with_unreadable_file_falls_back_without_throwing', () {
    // A CUE with no FILE entry at all must not raise.
    final cuePath = p.join(tmpDir.path, 'empty.cue');
    File(cuePath).writeAsStringSync('TRACK 01 MODE1/2352\n');

    final info = detectFile(cuePath);
    expect(info['format'], equals('CUE'));
    expect(info['platform'], equals('UNKNOWN'));
  });
}
