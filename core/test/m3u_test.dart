import 'dart:io';

import 'package:openrom_core/openrom_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tmpDir;

  setUp(() {
    tmpDir = Directory.systemTemp.createTempSync('m3u_test_');
  });

  tearDown(() {
    if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
  });

  List<String> _createDiscs(List<String> names) {
    return names.map((n) {
      final path = p.join(tmpDir.path, n);
      File(path).writeAsStringSync('disc');
      return path;
    }).toList();
  }

  test('m3u_includes_all_discs_in_sequential_order', () {
    final discs = _createDiscs([
      'Final Fantasy VII (Disc 3).cue',
      'Final Fantasy VII (Disc 1).cue',
      'Final Fantasy VII (Disc 2).cue',
    ]);

    final out = p.join(tmpDir.path, 'Final Fantasy VII.m3u');
    final created = generateM3u(discFiles: discs, outputPath: out);

    final lines = File(created)
        .readAsLinesSync()
        .where((l) => l.trim().isNotEmpty)
        .toList();

    expect(lines.length, equals(3));
    expect(lines[0], endsWith('Final Fantasy VII (Disc 1).cue'));
    expect(lines[1], endsWith('Final Fantasy VII (Disc 2).cue'));
    expect(lines[2], endsWith('Final Fantasy VII (Disc 3).cue'));
  });

  test('m3u_preserves_exact_filename_casing', () {
    final discs = _createDiscs([
      'Legend of Dragoon (Disc 1).CHD',
      'Legend of Dragoon (Disc 2).CHD',
    ]);

    final out = p.join(tmpDir.path, 'LoD.m3u');
    final created = generateM3u(discFiles: discs, outputPath: out);

    final content = File(created).readAsStringSync();
    // The original casing must survive verbatim — no .toLowerCase().
    expect(content, contains('Legend of Dragoon (Disc 1).CHD'));
    expect(content, contains('Legend of Dragoon (Disc 2).CHD'));
    expect(content, isNot(contains('legend of dragoon')));
    expect(content, isNot(contains('.chd')));
  });

  test('m3u_order_is_stable_for_names_without_disc_marker', () {
    final discs = _createDiscs([
      'Game.cue',
      'Game (Disc 2).cue',
      'Game (Disc 1).cue',
    ]);

    final out = p.join(tmpDir.path, 'game.m3u');
    final created = generateM3u(discFiles: discs, outputPath: out);

    final lines = File(created)
        .readAsLinesSync()
        .where((l) => l.trim().isNotEmpty)
        .toList();

    expect(lines[0], endsWith('Game (Disc 1).cue'));
    expect(lines[1], endsWith('Game (Disc 2).cue'));
    expect(lines[2], endsWith('Game.cue'));
  });

  test('orderDiscFiles_sorts_disc_sets_sequentially', () {
    final ordered = orderDiscFiles([
      '/roms/Game (Disc 3).cue',
      '/roms/Game (Disc 10).cue',
      '/roms/Game (Disc 1).cue',
      '/roms/Game (Disc 2).cue',
    ]);

    expect(
      ordered.map(p.basename).toList(),
      equals([
        'Game (Disc 1).cue',
        'Game (Disc 2).cue',
        'Game (Disc 3).cue',
        'Game (Disc 10).cue',
      ]),
    );
  });

  test('m3u_absolute_paths_keep_casing', () {
    final discs = _createDiscs(['Disc (Disc 1).Bin', 'Disc (Disc 2).Bin']);
    final out = p.join(tmpDir.path, 'abs.m3u');
    final created = generateM3u(
      discFiles: discs,
      outputPath: out,
      relative: false,
    );

    final content = File(created).readAsStringSync();
    expect(content, contains('Disc (Disc 1).Bin'));
    expect(content, contains('Disc (Disc 2).Bin'));
  });
}
