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
      // WUA conversion is a community extension; core advertises no target.
      expect(info['valid_targets'], isEmpty);
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
        ['CHD', 'CSO', 'ECM', 'RVZ'],
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
        ['CHD', 'CSO', 'ECM', 'RVZ'],
      ],
      [
        'game360.cci',
        'CCI',
        <String>[],
      ],
      [
        'game360.zar',
        'ZAR',
        <String>[],
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

  test('decoupled_route_reports_community_extension', () async {
    final tmpDir = Directory.systemTemp.createTempSync('decoupled_route_');
    try {
      // .cci / .zar / .xiso / nkit / wua are no longer handled by core: the
      // converter must fail with the friendly extension message, never a
      // missing-binary exception.
      final cases = [
        ('dummy.cci', 'ISO'),
        ('dummy.zar', 'ISO'),
        ('game.wua', 'ISO'),
        ('game.wud', 'ISO'),
      ];

      for (final (filename, target) in cases) {
        final file = p.join(tmpDir.path, filename);
        File(file).writeAsBytesSync(List<int>.filled(100, 0));

        final job = ConversionJob(
          filepath: file,
          outputDir: tmpDir.path,
          targetFormat: target,
        );

        final converter = Converter();
        final success = await converter.convert(job);

        expect(success, isFalse, reason: '$filename should not convert');
        expect(job.status, equals('Failed'));
        expect(
          job.error,
          equals(
            'Format requires a community extension (e.g. NKit or Xbox Suite). '
            'Please install it from the OpenROM Extension Store.',
          ),
          reason: 'unexpected error for $filename',
        );
      }
    } finally {
      tmpDir.deleteSync(recursive: true);
    }
  });

  test('iso_to_xiso_requires_community_extension', () async {
    final tmpDir = Directory.systemTemp.createTempSync('xiso_route_');
    try {
      final iso = p.join(tmpDir.path, 'game.iso');
      File(iso).writeAsBytesSync(List<int>.filled(2048, 0));

      final job = ConversionJob(
        filepath: iso,
        outputDir: tmpDir.path,
        targetFormat: 'XISO',
      );

      final converter = Converter();
      final success = await converter.convert(job);

      expect(success, isFalse);
      expect(job.error, equals(communityExtensionError));
    } finally {
      tmpDir.deleteSync(recursive: true);
    }
  });

  test('config_exposes_only_core_tools', () {
    // The decoupled tools must be gone from the bundled-tool registry.
    for (final tool in ['nkit', 'saturn-patcher', 'xgdtool', 'extract-xiso']) {
      expect(defaultConfig.containsKey(tool), isFalse, reason: tool);
    }
    for (final tool in [
      'chdman',
      'nodtool',
      'maxcso',
      'xdelta3',
      'ecm',
      'unecm',
    ]) {
      expect(defaultConfig.containsKey(tool), isTrue, reason: tool);
    }
  });

  test('decoupled_routes_are_not_builtin_so_plugins_can_claim_them', () {
    // A plugin may only shadow a built-in route with "override": true. These
    // routes were decoupled, so they must be absent from builtinRoutes —
    // otherwise a normal extension could not serve them.
    for (final key in [
      'CCI->ISO',
      'ZAR->ISO',
      'ISO->XISO',
      'XISO->FILES',
      'WUD->ISO',
      'WUX->ISO',
      'WUA->ISO',
      'WUA->WUD',
      'NKIT->ISO',
      'ISO->NKIT',
    ]) {
      expect(builtinRoutes.contains(key), isFalse, reason: key);
    }

    // The routes that remain built-in are still protected.
    expect(builtinRoutes.contains('ISO->CHD'), isTrue);
    expect(builtinRoutes.contains('ISO->RVZ'), isTrue);
    expect(builtinRoutes.contains('CSO->ISO'), isTrue);
  });

  test('unknown_iso_conversion_without_media_fails_safely', () async {
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
      final success = await converter.convert(job);

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

  test('unknown_iso_conversion_with_media_override_routes_correctly', () async {
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
      await converter.convert(jobCd);
      expect(jobCd.error, contains('Tool not found'));
      expect(jobCd.error, isNot(contains('Platform could not be detected')));

      final jobDvd = ConversionJob(
        filepath: isoPath,
        outputDir: tmpDir.path,
        targetFormat: 'CHD',
        media: 'dvd',
      );
      await converter.convert(jobDvd);
      expect(jobDvd.error, contains('Tool not found'));
      expect(jobDvd.error, isNot(contains('Platform could not be detected')));
    } finally {
      saveConfig({});
      tmpDir.deleteSync(recursive: true);
    }
  });

  test('unmapped_custom_platform_conversion_without_media_fails_safely',
      () async {
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
      final success = await converter.convert(job);

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

  test('unmapped_custom_platform_conversion_with_media_override_succeeds',
      () async {
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
      await converter.convert(job);

      expect(job.error, contains('Tool not found'));
      expect(job.error, isNot(contains('Platform could not be detected')));
    } finally {
      saveConfig({});
      tmpDir.deleteSync(recursive: true);
    }
  });
}
