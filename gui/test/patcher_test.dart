// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gui/patcher/patcher.dart';
import 'package:gui/patcher/patcher_factory.dart';

void main() {
  group('PatcherFactory Tests', () {
    test('Identifies supported patch extensions', () {
      expect(PatcherFactory.supportedExtensions.contains('ssp'), isTrue);
      expect(PatcherFactory.isSupportedPatch('game.ips'), isTrue);
      expect(PatcherFactory.isSupportedPatch('game.IPS32'), isTrue);
      expect(PatcherFactory.isSupportedPatch('game.bps'), isTrue);
      expect(PatcherFactory.isSupportedPatch('game.xdelta'), isTrue);
      expect(PatcherFactory.isSupportedPatch('game.ssp'), isTrue);
      expect(PatcherFactory.isSupportedPatch('game.iso'), isFalse);
    });

    test('Identifies SSP patch', () {
      expect(PatcherFactory.isSspPatch('game.ssp'), isTrue);
      expect(PatcherFactory.isSspPatch('GAME.SSP'), isTrue);
      expect(PatcherFactory.isSspPatch('game.ips'), isFalse);
    });

    test('Returns human-readable format names', () {
      expect(PatcherFactory.formatName('patch.bps'), 'BPS');
      expect(PatcherFactory.formatName('patch.ips'), 'IPS');
      expect(PatcherFactory.formatName('patch.vcdiff'), 'xdelta');
      expect(PatcherFactory.formatName('game.ssp'), 'SSP (Saturn)');
      expect(PatcherFactory.formatName('patch.unknown'), isNull);
    });

    test('PatcherFactory.create throws PatchException for SSP', () {
      expect(
        () => PatcherFactory.create(
          patchFile: File('game.ssp'),
          romFile: File('game.bin'),
          outputFile: File('game_patched.bin'),
        ),
        throwsA(isA<PatchException>()),
      );
    });
  });
}
