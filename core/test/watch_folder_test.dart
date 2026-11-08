import 'dart:io';

import 'package:openrom_core/openrom_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// A Converter that never shells out; records the jobs it was asked to run.
class _FakeConverter extends Converter {
  final List<ConversionJob> converted = [];
  bool result;

  _FakeConverter({this.result = true});

  @override
  Future<bool> convert(ConversionJob job) async {
    converted.add(job);
    job.status = result ? 'Done' : 'Failed';
    return result;
  }
}

/// Drives [SizeProbe] from a scripted list of sizes (null = file gone).
class _ScriptedProbe {
  final List<int?> sizes;
  int calls = 0;
  _ScriptedProbe(this.sizes);

  int? call(String _) {
    final size = calls < sizes.length ? sizes[calls] : sizes.last;
    calls++;
    return size;
  }
}

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('openrom_watch_');
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  WatchFolderDaemon build({
    required SizeProbe probe,
    Converter? converter,
    int settleSeconds = 2,
  }) {
    return WatchFolderDaemon(
      inputDir: p.join(tmp.path, 'in'),
      outputDir: p.join(tmp.path, 'out'),
      targetFormat: 'CHD',
      settleSeconds: settleSeconds,
      converter: converter,
      sizeProbe: probe,
      sleeper: (_) async {},
      pollInterval: const Duration(milliseconds: 500),
    );
  }

  group('awaitStable (write-lock debounce)', () {
    test('returns the size once it is stable for the settle window', () async {
      // 2s settle at 500ms polls => 4 consecutive unchanged readings.
      final probe = _ScriptedProbe([100, 100, 100, 100, 100]);
      final daemon = build(probe: probe);
      expect(await daemon.awaitStable('/x/rom.iso'), 100);
    });

    test('does not settle while the file is still growing', () async {
      // Keeps growing: each new reading resets the stability counter.
      final probe = _ScriptedProbe([10, 20, 30, 40, 50, 50, 50, 50, 50]);
      final daemon = build(probe: probe);
      expect(await daemon.awaitStable('/x/rom.iso'), 50);
      // It must not have settled on an intermediate (growing) size.
      expect(probe.calls, greaterThan(4));
    });

    test('returns null when the file vanishes mid-wait', () async {
      final probe = _ScriptedProbe([100, null]);
      final daemon = build(probe: probe);
      expect(await daemon.awaitStable('/x/rom.iso'), isNull);
    });
  });

  group('handleFile', () {
    test('skips unsupported extensions without converting', () async {
      final converter = _FakeConverter();
      final probe = _ScriptedProbe([10]);
      final daemon = build(probe: probe, converter: converter);

      final ok = await daemon.handleFile(p.join(tmp.path, 'in', 'notes.txt'));
      expect(ok, isFalse);
      expect(converter.converted, isEmpty);
    });

    test('converts a supported file once it has settled', () async {
      final inDir = Directory(p.join(tmp.path, 'in'))..createSync();
      final outDir = Directory(p.join(tmp.path, 'out'))..createSync();
      final rom = File(p.join(inDir.path, 'game.iso'))
        ..writeAsBytesSync(List<int>.filled(16, 0));

      final converter = _FakeConverter();
      final probe = _ScriptedProbe([16, 16, 16, 16, 16]);
      final daemon = build(probe: probe, converter: converter);

      final ok = await daemon.handleFile(rom.path);
      expect(ok, isTrue);
      expect(converter.converted, hasLength(1));
      expect(converter.converted.first.filepath, rom.path);
      expect(converter.converted.first.outputDir, outDir.path);
      expect(converter.converted.first.targetFormat, 'CHD');
    });

    test('never converts the same path twice', () async {
      final inDir = Directory(p.join(tmp.path, 'in'))..createSync();
      Directory(p.join(tmp.path, 'out')).createSync();
      final rom = File(p.join(inDir.path, 'game.iso'))
        ..writeAsBytesSync(List<int>.filled(16, 0));

      final converter = _FakeConverter();
      final probe = _ScriptedProbe([16, 16, 16, 16, 16]);
      final daemon = build(probe: probe, converter: converter);

      await daemon.handleFile(rom.path);
      final second = await daemon.handleFile(rom.path);
      expect(second, isFalse);
      expect(converter.converted, hasLength(1));
    });

    test('ignores files that land in the output folder', () async {
      final outDir = Directory(p.join(tmp.path, 'out'))..createSync();
      final produced = File(p.join(outDir.path, 'game.chd'))
        ..writeAsBytesSync(List<int>.filled(8, 0));

      final converter = _FakeConverter();
      final daemon = build(probe: _ScriptedProbe([8]), converter: converter);

      final ok = await daemon.handleFile(produced.path);
      expect(ok, isFalse);
      expect(converter.converted, isEmpty);
    });

    test('deletes the source after a successful conversion when asked',
        () async {
      final inDir = Directory(p.join(tmp.path, 'in'))..createSync();
      Directory(p.join(tmp.path, 'out')).createSync();
      final rom = File(p.join(inDir.path, 'game.iso'))
        ..writeAsBytesSync(List<int>.filled(16, 0));

      final converter = _FakeConverter();
      final daemon = WatchFolderDaemon(
        inputDir: inDir.path,
        outputDir: p.join(tmp.path, 'out'),
        deleteSource: true,
        settleSeconds: 2,
        converter: converter,
        sizeProbe: _ScriptedProbe([16, 16, 16, 16, 16]),
        sleeper: (_) async {},
        pollInterval: const Duration(milliseconds: 500),
      );

      await daemon.handleFile(rom.path);
      expect(rom.existsSync(), isFalse);
    });

    test('keeps the source when the conversion fails', () async {
      final inDir = Directory(p.join(tmp.path, 'in'))..createSync();
      Directory(p.join(tmp.path, 'out')).createSync();
      final rom = File(p.join(inDir.path, 'game.iso'))
        ..writeAsBytesSync(List<int>.filled(16, 0));

      final converter = _FakeConverter(result: false);
      final daemon = WatchFolderDaemon(
        inputDir: inDir.path,
        outputDir: p.join(tmp.path, 'out'),
        deleteSource: true,
        settleSeconds: 2,
        converter: converter,
        sizeProbe: _ScriptedProbe([16, 16, 16, 16, 16]),
        sleeper: (_) async {},
        pollInterval: const Duration(milliseconds: 500),
      );

      final ok = await daemon.handleFile(rom.path);
      expect(ok, isFalse);
      expect(rom.existsSync(), isTrue);
    });
  });

  group('sweepExisting', () {
    test('processes supported files already present in the input dir',
        () async {
      final inDir = Directory(p.join(tmp.path, 'in'))..createSync();
      Directory(p.join(tmp.path, 'out')).createSync();
      File(p.join(inDir.path, 'a.iso'))
          .writeAsBytesSync(List<int>.filled(16, 0));
      File(p.join(inDir.path, 'b.iso'))
          .writeAsBytesSync(List<int>.filled(16, 0));
      File(p.join(inDir.path, 'readme.txt')).writeAsStringSync('nope');

      final converter = _FakeConverter();
      final daemon = build(
        probe: _ScriptedProbe([16, 16, 16, 16, 16]),
        converter: converter,
      );

      await daemon.sweepExisting();
      expect(converter.converted, hasLength(2));
      expect(
        converter.converted.map((j) => p.basename(j.filepath)).toSet(),
        {'a.iso', 'b.iso'},
      );
    });
  });
}
