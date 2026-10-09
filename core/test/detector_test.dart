import 'dart:io';

import 'package:openrom_core/openrom_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('wua_file_detection_and_targets', () {
    final tmpDir = Directory.systemTemp.createTempSync('wua_test_');
    try {
      final wuaPath = p.join(tmpDir.path, 'game.wua');
      File(wuaPath).writeAsBytesSync(List<int>.filled(100, 0));

      final info = detectFile(wuaPath);
      expect(info['format'], equals('WUA'));
      expect(info['platform'], equals('Wii U (ZArchive)'));
      expect(info['valid_targets'], equals(['ISO', 'WUD']));

      final cmd = getCommandPreview('WUA', 'ISO', 'game.wua');
      expect(cmd, equals('nkit convert -i "game.wua" -o "game.iso"'));
    } finally {
      tmpDir.deleteSync(recursive: true);
    }
  });

  test('unknown_iso_platform_detection', () {
    final tmpDir = Directory.systemTemp.createTempSync('unknown_iso_test_');
    try {
      final isoPath = p.join(tmpDir.path, 'unidentified.iso');
      final file = File(isoPath);
      file.writeAsBytesSync(List<int>.filled(2048, 0));

      final res = detectFile(isoPath);
      expect(res['format'], equals('ISO'));
      expect(res['platform'], equals('UNKNOWN'));
    } finally {
      tmpDir.deleteSync(recursive: true);
    }
  });

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
      [
        'tom_jerry.bin.ecm',
        'ECM',
        ['ISO', 'BIN'],
      ],
      [
        'game.iso',
        'ISO',
        ['CHD', 'CSO', 'ECM', 'XISO', 'RVZ', 'NKIT'],
      ],
      [
        'disc.bin',
        'BIN',
        ['CHD', 'ECM'],
      ],
      [
        'disc.cue',
        'CUE',
        ['CHD'],
      ],
      [
        'sonic.gdi',
        'GDI',
        ['CHD'],
      ],
      [
        'halo.chd',
        'CHD',
        ['ISO', 'BIN/CUE'],
      ],
      [
        'psp_game.cso',
        'CSO',
        ['ISO'],
      ],
      [
        'psp_game.zso',
        'ZSO',
        ['ISO'],
      ],
      [
        'xbox_iso.iso',
        'ISO',
        ['CHD', 'CSO', 'ECM', 'XISO', 'RVZ', 'NKIT'],
      ],
      [
        'game360.cci',
        'CCI',
        ['ISO'],
      ],
      [
        'game360.zar',
        'ZAR',
        ['ISO'],
      ],
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
        expect(
          res['format'],
          equals(expectedFmt),
          reason: 'Format mismatch for $filename',
        );
        expect(
          res['valid_targets'],
          equals(expectedTargets),
          reason: 'Targets mismatch for $filename',
        );
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

  test('unknown_iso_conversion_without_media_fails_safely', () {
    final tmpDir = Directory.systemTemp.createTempSync('unknown_iso_conv_');
    try {
      final isoPath = p.join(tmpDir.path, 'unidentified.iso');
      File(isoPath).writeAsBytesSync(List<int>.filled(2048, 0));

      final job = ConversionJob(
        filepath: isoPath,
        outputDir: tmpDir.path,
        targetFormat: 'CHD',
      );

      final converter = Converter();
      final success = converter.convert(job);

      expect(success, isFalse);
      expect(job.status, equals('Failed'));
      expect(
        job.error,
        equals(
          "Unsupported or ambiguous media type for platform 'UNKNOWN'. Please specify --media cd or --media dvd.",
        ),
      );
    } finally {
      tmpDir.deleteSync(recursive: true);
    }
  });

  test('unknown_iso_conversion_with_media_override_routes_correctly', () {
    final tmpDir = Directory.systemTemp.createTempSync('unknown_iso_override_');
    try {
      final isoPath = p.join(tmpDir.path, 'unidentified.iso');
      File(isoPath).writeAsBytesSync(List<int>.filled(2048, 0));

      saveConfig({'chdman': p.join(tmpDir.path, 'missing_chdman')});

      final jobCd = ConversionJob(
        filepath: isoPath,
        outputDir: tmpDir.path,
        targetFormat: 'CHD',
        media: 'cd',
      );

      final converter = Converter();
      converter.convert(jobCd);
      expect(jobCd.error, contains('Tool not found'));
      expect(jobCd.error, isNot(contains('Platform could not be detected')));

      final jobDvd = ConversionJob(
        filepath: isoPath,
        outputDir: tmpDir.path,
        targetFormat: 'CHD',
        media: 'dvd',
      );
      converter.convert(jobDvd);
      expect(jobDvd.error, contains('Tool not found'));
      expect(jobDvd.error, isNot(contains('Platform could not be detected')));
    } finally {
      saveConfig({});
      tmpDir.deleteSync(recursive: true);
    }
  });

  test('unmapped_custom_platform_conversion_without_media_fails_safely', () {
    final tmpDir =
        Directory.systemTemp.createTempSync('unmapped_platform_test_');
    try {
      final isoPath = p.join(tmpDir.path, 'custom.iso');
      File(isoPath).writeAsBytesSync(List<int>.filled(2048, 0));

      final job = ConversionJob(
        filepath: isoPath,
        outputDir: tmpDir.path,
        targetFormat: 'CHD',
        forcePlatform: 'CustomConsoleX',
      );

      final converter = Converter();
      final success = converter.convert(job);

      expect(success, isFalse);
      expect(job.status, equals('Failed'));
      expect(
        job.error,
        equals(
          "Unsupported or ambiguous media type for platform 'CustomConsoleX'. Please specify --media cd or --media dvd.",
        ),
      );
    } finally {
      tmpDir.deleteSync(recursive: true);
    }
  });

  test('unmapped_custom_platform_conversion_with_media_override_succeeds', () {
    final tmpDir =
        Directory.systemTemp.createTempSync('unmapped_platform_override_');
    try {
      final isoPath = p.join(tmpDir.path, 'custom.iso');
      File(isoPath).writeAsBytesSync(List<int>.filled(2048, 0));

      saveConfig({'chdman': p.join(tmpDir.path, 'missing_chdman')});

      final job = ConversionJob(
        filepath: isoPath,
        outputDir: tmpDir.path,
        targetFormat: 'CHD',
        forcePlatform: 'CustomConsoleX',
        media: 'cd',
      );

      final converter = Converter();
      converter.convert(job);

      expect(job.error, contains('Tool not found'));
      expect(job.error, isNot(contains('Platform could not be detected')));
    } finally {
      saveConfig({});
      tmpDir.deleteSync(recursive: true);
    }
  });
}
