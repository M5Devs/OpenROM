// OpenROM — .orskin bundle tests
// M5 Dev | GPL v3

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gui/models/skin_manifest.dart';
import 'package:gui/models/theme_config.dart';
import 'package:gui/services/skin_manager.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tmp;
  late SkinManager manager;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('orskin_test');
    manager = SkinManager(configDir: tmp);
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  ThemeConfig sampleTheme() => ThemeConfig.defaultTheme().copyWith(
        name: 'Neon Nights',
        accent: const Color(0xffe94560),
        accentSecondary: const Color(0xff00f0ff),
        borderColor: const Color(0xff2d334d),
        borderRadius: 18,
        wallpaperOpacity: 0.4,
        wallpaperBlur: 6,
      );

  List<int> manifestBytes(String id) => utf8.encode(
        jsonEncode(
          SkinManifest.fromTheme(sampleTheme(), id: id, author: 'M5 Dev')
              .toJson(),
        ),
      );

  group('SkinManifest', () {
    test('serialises the documented .orskin schema', () {
      final json = SkinManifest.fromTheme(
        sampleTheme(),
        id: 'neon-nights',
        author: 'M5 Dev',
      ).toJson();

      expect(json['id'], 'neon-nights');
      expect(json['name'], 'Neon Nights');
      expect(json['author'], 'M5 Dev');
      expect(json['specVersion'], 1);
      expect(json['colors']['accent'], '#e94560');
      expect(json['colors']['accentSecondary'], '#00f0ff');
      expect(json['colors']['border'], '#2d334d');
      expect(json['openrom']['layout'], isNotNull);
    });

    test('sanitizeId strips path traversal and separators', () {
      expect(SkinManifest.sanitizeId('../../etc/passwd'), 'etc-passwd');
      expect(SkinManifest.sanitizeId('My Skin!!'), 'my-skin');
      expect(SkinManifest.sanitizeId(''), 'custom-skin');
      expect(SkinManifest.sanitizeId('/'), 'custom-skin');
    });
  });

  group('SkinManager export/import', () {
    test('round-trips every palette field', () async {
      final theme = sampleTheme();
      final out = File(p.join(tmp.path, 'neon.orskin'));

      final exported = manager.exportSkin(
        theme: theme,
        outputPath: out,
        author: 'M5 Dev',
      );
      expect(exported.isOk, isTrue, reason: exported.error);
      expect(out.existsSync(), isTrue);

      final imported = await manager.importSkin(out);
      expect(imported.isOk, isTrue, reason: imported.error);

      final t = imported.value!.theme;
      expect(t.name, 'Neon Nights');
      expect(t.background, theme.background);
      expect(t.surface, theme.surface);
      expect(t.accent, theme.accent);
      expect(t.accentSecondary, theme.accentSecondary);
      expect(t.borderColor, theme.borderColor);
      expect(t.cardBg, theme.cardBg);
      expect(t.sidebarBg, theme.sidebarBg);
      expect(t.terminalBg, theme.terminalBg);
      expect(t.borderRadius, 18);
      expect(t.wallpaperOpacity, closeTo(0.4, 1e-6));
      expect(t.wallpaperBlur, closeTo(6, 1e-6));
      expect(t.layout, theme.layout);
      expect(imported.value!.author, 'M5 Dev');
    });

    test('embeds a wallpaper and re-points it on import', () async {
      final wp = File(p.join(tmp.path, 'wallpaper.png'))
        ..writeAsBytesSync(const [1, 2, 3, 4, 5]);
      final out = File(p.join(tmp.path, 'skin.orskin'));

      expect(
        manager
            .exportSkin(theme: sampleTheme(), outputPath: out, wallpaper: wp)
            .isOk,
        isTrue,
      );

      final imported = await manager.importSkin(out);
      final path = imported.value!.theme.wallpaperPath;
      expect(path, isNotNull);
      expect(File(path!).existsSync(), isTrue);
    });

    test('listInstalledSkins returns imported skins', () async {
      final out = File(p.join(tmp.path, 'a.orskin'));
      manager.exportSkin(theme: sampleTheme(), outputPath: out);
      await manager.importSkin(out);

      final skins = manager.listInstalledSkins();
      expect(skins.map((s) => s.theme.name), contains('Neon Nights'));
    });

    test('removeSkin deletes an installed skin', () async {
      final out = File(p.join(tmp.path, 'a.orskin'));
      manager.exportSkin(theme: sampleTheme(), outputPath: out);
      await manager.importSkin(out);

      expect(manager.removeSkin('neon-nights'), isTrue);
      expect(manager.listInstalledSkins(), isEmpty);
    });
  });

  group('SkinManager safety', () {
    test('rejects a Zip-Slip entry and writes nothing outside the skin dir',
        () async {
      final archive = Archive();
      final m = manifestBytes('evil');
      archive.addFile(ArchiveFile('theme.json', m.length, m));
      final payload = utf8.encode('pwned');
      archive.addFile(
        ArchiveFile('../../escaped.txt', payload.length, payload),
      );
      final out = File(p.join(tmp.path, 'evil.orskin'))
        ..writeAsBytesSync(ZipEncoder().encode(archive)!);

      final result = await manager.importSkin(out);
      expect(result.isOk, isFalse);
      expect(result.error, contains('escapes'));
      expect(File(p.join(tmp.path, 'escaped.txt')).existsSync(), isFalse);
    });

    test('rejects a symbolic-link entry', () async {
      // archive's ZipEncoder never emits symlinks (it writes an MS-DOS
      // versionMadeBy), so use a real UNIX-created fixture: a ZIP holding
      // theme.json plus a symlink entry named "link".
      const fixtureBase64 =
          'UEsDBBQAAAAIAFBTZl3ywcryWgAAAHYAAAAKAAAAdGhlbWUuanNvbi3NTQqAIBCG4avEtA2xbfsO'
          'Yiol/gyMKYF49xppds8LH9PAGdgmsNUFWCZIKlr2/luV+0Li8jCrpewwsVchheQW0YyJUeTZGgNS'
          '/kqDQ2l/EpY0fsxyHPT+AlBLAwQUAAAAAAAAACEAxwF09Q0AAAANAAAABAAAAGxpbmsuLi9ldGMv'
          'cGFzc3dkUEsBAhQDFAAAAAgAUFNmXfLByvJaAAAAdgAAAAoAAAAAAAAAAAAAAIABAAAAAHRoZW1l'
          'Lmpzb25QSwECFAMUAAAAAAAAACEAxwF09Q0AAAANAAAABAAAAAAAAAAAAAAA/6GCAAAAbGlua1BL'
          'BQYAAAAAAgACAGoAAACxAAAAAAA=';
      final out = File(p.join(tmp.path, 'symlink.orskin'))
        ..writeAsBytesSync(base64Decode(fixtureBase64));

      final result = await manager.importSkin(out);
      expect(result.isOk, isFalse);
      expect(result.error, contains('symbolic link'));
    });

    test('rejects an archive without theme.json', () async {
      final archive = Archive();
      final data = utf8.encode('hello');
      archive.addFile(ArchiveFile('README.md', data.length, data));
      final out = File(p.join(tmp.path, 'no.orskin'))
        ..writeAsBytesSync(ZipEncoder().encode(archive)!);

      final result = await manager.importSkin(out);
      expect(result.isOk, isFalse);
      expect(result.error, contains('theme.json'));
    });

    test('rejects a non-ZIP file', () async {
      final out = File(p.join(tmp.path, 'junk.orskin'))
        ..writeAsStringSync('this is not a zip');
      final result = await manager.importSkin(out);
      expect(result.isOk, isFalse);
      expect(result.error, contains('valid .orskin'));
    });

    test('rejects a malformed theme.json', () async {
      final archive = Archive();
      final data = utf8.encode('{ not json');
      archive.addFile(ArchiveFile('theme.json', data.length, data));
      final out = File(p.join(tmp.path, 'bad.orskin'))
        ..writeAsBytesSync(ZipEncoder().encode(archive)!);

      final result = await manager.importSkin(out);
      expect(result.isOk, isFalse);
      expect(result.error, contains('Malformed'));
    });
  });
}
