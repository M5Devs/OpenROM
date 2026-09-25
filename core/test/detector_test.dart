import 'dart:io';
import 'package:openrom_core/openrom_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('get_extension', () {
    expect(getExtension('tom_jerry.bin.ecm'), equals('ecm'));
    expect(getExtension('game.iso'), equals('iso'));
    expect(getExtension('disc.cue'), equals('cue'));
    expect(getExtension('archive.tar.gz'), equals('gz'));
    expect(getExtension('game.nkit.iso'), equals('nkit.iso'));
  });

  test('get_output_name', () {
    expect(getOutputName('tom_jerry.bin.ecm', 'bin'), equals('tom_jerry.bin'));
    expect(getOutputName('tom_jerry.bin.ecm', '.bin'), equals('tom_jerry.bin'));
    expect(getOutputName('game.iso', 'chd'), equals('game.chd'));
    expect(getOutputName('disc.bin', 'ecm'), equals('disc.ecm'));
  });

  test('detect_file_cases', () {
    final cases = [
      ['tom_jerry.bin.ecm', 'ECM', ['ISO', 'BIN']],
      ['game.iso', 'ISO', ['CHD', 'CSO', 'ECM', 'XISO', 'RVZ', 'NKIT']],
      ['disc.bin', 'BIN', ['CHD', 'ECM']],
      ['disc.cue', 'CUE', ['CHD']],
      ['sonic.gdi', 'GDI', ['CHD']],
      ['halo.chd', 'CHD', ['ISO', 'BIN/CUE']],
      ['psp_game.cso', 'CSO', ['ISO']],
      ['psp_game.zso', 'ZSO', ['ISO']],
      ['xbox_iso.iso', 'ISO', ['CHD', 'CSO', 'ECM', 'XISO', 'RVZ', 'NKIT']],
      ['game360.cci', 'CCI', ['ISO']],
      ['game360.zar', 'ZAR', ['ISO']],
    ];

    final tmpDir = Directory.systemTemp.createTempSync('detector_test_');
    try {
      for (final c in cases) {
        final filename = c[0] as String;
        final expectedFmt = c[1] as String;
        final expectedTargets = c[2] as List<String>;

        final filepath = p.join(tmpDir.path, filename);
        final file = File(filepath);
        file.writeAsBytesSync(List<int>.filled(1024, 0));

        final res = detectFile(filepath);
        expect(res.containsKey('error'), isFalse, reason: 'Error in $filename');
        expect(res['format'], equals(expectedFmt), reason: 'Format mismatch for $filename');
        expect(res['valid_targets'], equals(expectedTargets), reason: 'Targets mismatch for $filename');
      }
    } finally {
      tmpDir.deleteSync(recursive: true);
    }
  });

  test('xbox_magic_detection', () {
    final xboxMagicBytes = 'MICROSOFT*XBOX*MEDIA'.codeUnits;
    final tmpDir = Directory.systemTemp.createTempSync('xbox_test_');
    try {
      final fastPath = p.join(tmpDir.path, 'xbox_fast.iso');
      final fastFile = File(fastPath);
      final raf1 = fastFile.openSync(mode: FileMode.write);
      raf1.writeFromSync(List<int>.filled(0x10000, 0));
      raf1.writeFromSync(xboxMagicBytes);
      raf1.writeFromSync(List<int>.filled(1024, 0));
      raf1.closeSync();

      final resFast = detectFile(fastPath);
      expect(resFast['platform'], equals('Xbox'));

      final slowPath = p.join(tmpDir.path, 'xbox_slow.iso');
      final slowFile = File(slowPath);
      final raf2 = slowFile.openSync(mode: FileMode.write);
      raf2.setPositionSync(0x2090000);
      raf2.writeFromSync(xboxMagicBytes);
      raf2.closeSync();

      final resSlow = detectFile(slowPath);
      expect(resSlow['platform'], equals('Xbox'));
    } finally {
      tmpDir.deleteSync(recursive: true);
    }
  });


  test('missing_tool_preflight_check', () {
    final tmpDir = Directory.systemTemp.createTempSync('missing_tool_test_');
    try {
      final dummyFile = p.join(tmpDir.path, 'dummy.cci');
      File(dummyFile).writeAsBytesSync(List<int>.filled(100, 0));

      // Force config to use a non-existent absolute tool path
      saveConfig({'xgdtool': p.join(tmpDir.path, 'missing_XGDTool')});

      final job = ConversionJob(
        filepath: dummyFile,
        outputDir: tmpDir.path,
        targetFormat: 'ISO',
      );

      final converter = Converter();
      final success = converter.convert(job);

      expect(success, isFalse);
      expect(job.status, equals('Failed'));
      expect(job.error, contains('Tool not found'));
      expect(job.error, contains('missing from the assets folder'));
    } finally {
      saveConfig({});
      tmpDir.deleteSync(recursive: true);
    }
  });

  test('config_xgdtool_path', () {
    final xgdtoolPath = getToolPath('xgdtool');
    expect(xgdtoolPath, isNotEmpty);
  });
}
