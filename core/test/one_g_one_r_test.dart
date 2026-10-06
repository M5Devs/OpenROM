import 'dart:io';

import 'package:openrom_core/openrom_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('extractCleanTitle removes extension and tags', () {
    expect(
      extractCleanTitle('Super Mario World (USA) (Rev 1).sfc'),
      equals('Super Mario World'),
    );
    expect(
      extractCleanTitle('Sonic the Hedgehog (Europe) [!].bin'),
      equals('Sonic the Hedgehog'),
    );
    expect(
      extractCleanTitle('Chrono Trigger (Japan) (v1.1).smc'),
      equals('Chrono Trigger'),
    );
  });

  test('1G1R region priority selection USA over EUR and JPN', () {
    final tmpDir = Directory.systemTemp.createTempSync('one_g_one_r_test_');
    try {
      final usaFile = p.join(tmpDir.path, 'Super Mario World (USA).sfc');
      final eurFile = p.join(tmpDir.path, 'Super Mario World (Europe).sfc');
      final jpnFile = p.join(tmpDir.path, 'Super Mario World (Japan).sfc');

      File(usaFile).writeAsBytesSync([1, 2, 3]);
      File(eurFile).writeAsBytesSync([1, 2, 3]);
      File(jpnFile).writeAsBytesSync([1, 2, 3]);

      final summary = filter1G1R(
        folderPath: tmpDir.path,
        regionPriority: ['USA', 'Europe', 'Japan'],
        dryRun: true,
      );

      expect(summary.totalFiles, equals(3));
      expect(summary.keptCount, equals(1));
      expect(summary.movedCount, equals(2));

      final winner = summary.results.firstWhere((r) => r.isWinner);
      expect(winner.filename, equals('Super Mario World (USA).sfc'));

      final dupes = summary.results
          .where((r) => !r.isWinner)
          .map((r) => r.filename)
          .toList();
      expect(dupes, contains('Super Mario World (Europe).sfc'));
      expect(dupes, contains('Super Mario World (Japan).sfc'));
    } finally {
      tmpDir.deleteSync(recursive: true);
    }
  });

  test('1G1R prefers revision version over base version', () {
    final tmpDir = Directory.systemTemp.createTempSync('one_g_one_r_rev_test_');
    try {
      final baseFile = p.join(tmpDir.path, 'Zelda (USA).sfc');
      final revFile = p.join(tmpDir.path, 'Zelda (USA) (Rev 1).sfc');

      File(baseFile).writeAsBytesSync([1, 2, 3]);
      File(revFile).writeAsBytesSync([1, 2, 3]);

      final summary = filter1G1R(
        folderPath: tmpDir.path,
        regionPriority: ['USA', 'Europe', 'Japan'],
        dryRun: true,
      );

      expect(summary.keptCount, equals(1));
      expect(summary.movedCount, equals(1));

      final winner = summary.results.firstWhere((r) => r.isWinner);
      expect(winner.filename, equals('Zelda (USA) (Rev 1).sfc'));
    } finally {
      tmpDir.deleteSync(recursive: true);
    }
  });

  test('1G1R moves duplicates when dryRun is false', () {
    final tmpDir = Directory.systemTemp.createTempSync(
      'one_g_one_r_move_test_',
    );
    try {
      final usaFile = p.join(tmpDir.path, 'Metroid (USA).sfc');
      final eurFile = p.join(tmpDir.path, 'Metroid (Europe).sfc');

      File(usaFile).writeAsBytesSync([1, 2, 3]);
      File(eurFile).writeAsBytesSync([1, 2, 3]);

      final summary = filter1G1R(
        folderPath: tmpDir.path,
        regionPriority: ['USA', 'Europe'],
        dryRun: false,
        moveDuplicates: true,
      );

      expect(summary.movedCount, equals(1));
      expect(File(usaFile).existsSync(), isTrue);
      expect(File(eurFile).existsSync(), isFalse);

      final dupPath = p.join(
        tmpDir.path,
        '_duplicates',
        'Metroid (Europe).sfc',
      );
      expect(File(dupPath).existsSync(), isTrue);
    } finally {
      tmpDir.deleteSync(recursive: true);
    }
  });

  test('1G1R dryRun does not move files or create duplicates folder', () {
    final tmpDir = Directory.systemTemp.createTempSync('one_g_one_r_dry_test_');
    try {
      final usaFile = p.join(tmpDir.path, 'Donkey Kong (USA).sfc');
      final eurFile = p.join(tmpDir.path, 'Donkey Kong (Europe).sfc');

      File(usaFile).writeAsBytesSync([1, 2, 3]);
      File(eurFile).writeAsBytesSync([1, 2, 3]);

      final summary = filter1G1R(
        folderPath: tmpDir.path,
        regionPriority: ['USA', 'Europe'],
        dryRun: true,
      );

      expect(summary.movedCount, equals(1));
      expect(File(usaFile).existsSync(), isTrue);
      expect(File(eurFile).existsSync(), isTrue);

      final dupDir = Directory(p.join(tmpDir.path, '_duplicates'));
      expect(dupDir.existsSync(), isFalse);
    } finally {
      tmpDir.deleteSync(recursive: true);
    }
  });
}
