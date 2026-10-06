import 'dart:io';

import 'package:openrom_core/openrom_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('chd_audio_codec_flac_default', () {
    final tmpDir = Directory.systemTemp.createTempSync('chd_codec_flac_');
    try {
      final cuePath = p.join(tmpDir.path, 'game.cue');
      File(cuePath).writeAsStringSync(
          'FILE "game.bin" BINARY\n  TRACK 01 MODE1/2352\n    INDEX 01 00:00:00');
      File(p.join(tmpDir.path, 'game.bin'))
          .writeAsBytesSync(List<int>.filled(100, 0));

      final mockChdman = p.join(tmpDir.path, 'mock_chdman');
      File(mockChdman).writeAsStringSync('#!/bin/sh\nexit 0');
      if (!Platform.isWindows) {
        Process.runSync('chmod', ['+x', mockChdman]);
      }
      saveConfig({'chdman': mockChdman});

      final job = ConversionJob(
        filepath: cuePath,
        outputDir: tmpDir.path,
        targetFormat: 'CHD',
        audioCodec: 'flac',
      );

      final logs = <String>[];
      final converter = Converter(onLogCb: (msg) => logs.add(msg));
      converter.convert(job);

      expect(job.audioCodec, equals('flac'));
      final cmdLog =
          logs.firstWhere((l) => l.contains('cmd:'), orElse: () => '');
      expect(cmdLog, contains('--compression cdlz,cdfl'));
    } finally {
      saveConfig({});
      tmpDir.deleteSync(recursive: true);
    }
  });

  test('chd_audio_codec_vorbis', () {
    final tmpDir = Directory.systemTemp.createTempSync('chd_codec_vorbis_');
    try {
      final cuePath = p.join(tmpDir.path, 'game.cue');
      File(cuePath).writeAsStringSync(
          'FILE "game.bin" BINARY\n  TRACK 01 MODE1/2352\n    INDEX 01 00:00:00');
      File(p.join(tmpDir.path, 'game.bin'))
          .writeAsBytesSync(List<int>.filled(100, 0));

      final mockChdman = p.join(tmpDir.path, 'mock_chdman');
      File(mockChdman).writeAsStringSync('#!/bin/sh\nexit 0');
      if (!Platform.isWindows) {
        Process.runSync('chmod', ['+x', mockChdman]);
      }
      saveConfig({'chdman': mockChdman});

      final job = ConversionJob(
        filepath: cuePath,
        outputDir: tmpDir.path,
        targetFormat: 'CHD',
        audioCodec: 'vorbis',
      );

      final logs = <String>[];
      final converter = Converter(onLogCb: (msg) => logs.add(msg));
      converter.convert(job);

      expect(job.audioCodec, equals('vorbis'));
      final cmdLog =
          logs.firstWhere((l) => l.contains('cmd:'), orElse: () => '');
      expect(cmdLog, contains('--compression cdlz,cdav'));
    } finally {
      saveConfig({});
      tmpDir.deleteSync(recursive: true);
    }
  });
}
