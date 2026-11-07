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
    test('serialises the documented .orskin v2 schema', () {
      final json = SkinManifest.fromTheme(
        sampleTheme(),
        id: 'neon-nights',
        author: 'M5 Dev',
      ).toJson();

      expect(json['id'], 'neon-nights');
      expect(json['name'], 'Neon Nights');
      expect(json['author'], 'M5 Dev');
      expect(json['specVersion'], 2);
      expect(json['colors']['accent'], '#e94560');
      expect(json['colors']['accentSecondary'], '#00f0ff');
      expect(json['colors']['border'], '#2d334d');
      expect(json['openrom']['layout'], isNotNull);
      // v2 geometry block, mirrored flat for v1 readers.
      expect(json['ui']['borderRadius'], 18);
      expect((json['ui']['wallpaperOpacity'] as num).toDouble(),
          closeTo(0.4, 1e-6));
      expect(json['borderRadius'], 18);
      // v2 asset flags default to false with no assets set.
      expect(json['hasCustomFont'], isFalse);
      expect(json['hasCustomIcons'], isFalse);
      expect(json['hasCustomDropzone'], isFalse);
    });

    test('derives v2 asset flags from theme asset paths', () {
      final theme = sampleTheme().copyWith(
        fontPath: '/tmp/fonts/MyFont.ttf',
        dropzonePath: '/tmp/dropzone.gif',
        iconDir: '/tmp/icons',
        hiddenTabs: const ['dreamcast', 'about'],
      );
      final manifest = SkinManifest.fromTheme(theme, id: 'x');
      final json = manifest.toJson();

      expect(manifest.hasCustomFont, isTrue);
      expect(manifest.fontFileName, 'MyFont.ttf');
      expect(manifest.hasCustomIcons, isTrue);
      expect(manifest.hasCustomDropzone, isTrue);
      expect(json['hasCustomFont'], isTrue);
      expect(json['fontFileName'], 'MyFont.ttf');
      expect(json['hiddenTabs'], ['dreamcast', 'about']);
    });

    test('loads a legacy v1 theme.json without extra assets', () {
      final v1 = {
        'id': 'legacy',
        'name': 'Legacy Skin',
        'author': 'Old Timer',
        'version': '1.0.0',
        'mode': 'dark',
        'specVersion': 1,
        'borderRadius': 8.0,
        'wallpaperOpacity': 0.5,
        'wallpaperBlur': 3.0,
        'colors': {
          'background': '#101010',
          'surface': '#181818',
          'card': '#202020',
          'accent': '#abcdef',
          'text': '#ffffff',
          'textMuted': '#888888',
        },
      };
      final skin = SkinManifest.fromJson(v1);

      expect(skin.id, 'legacy');
      expect(skin.name, 'Legacy Skin');
      // Flat v1 geometry is honoured.
      expect(skin.theme.borderRadius, 8.0);
      expect(skin.theme.wallpaperOpacity, closeTo(0.5, 1e-6));
      expect(skin.theme.wallpaperBlur, closeTo(3.0, 1e-6));
      expect(skin.theme.accent, const Color(0xffabcdef));
      // v2 fields default cleanly.
      expect(skin.hasCustomFont, isFalse);
      expect(skin.fontFileName, isNull);
      expect(skin.hiddenTabs, isEmpty);
    });

    test('hiddenTabs is filtered to known tab ids', () {
      final skin = SkinManifest.fromJson({
        'id': 'x',
        'name': 'X',
        'hiddenTabs': ['dreamcast', 'bogus', 'about'],
      });
      expect(skin.hiddenTabs, ['dreamcast', 'about']);
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

  group('SkinManager v2 assets', () {
    /// A minimal but valid animated GIF (2 frames) — exercises GIF decoding
    /// paths without needing an image library.
    const animatedGifBase64 =
        'R0lGODlhAQABAIAAAAAAAP///yH/C05FVFNDQVBFMi4wAwEAAAAh+QQJBwAAACwAAAAAAQAB'
        'AAACAkQAACH5BAkHAAAALAAAAAABAAEAAAICRAAAOw==';

    test('packs and unpacks a full v2 bundle (gif wallpaper, font, icons)',
        () async {
      // Arrange: a wallpaper GIF, a dropzone GIF, a fake font, and two icons.
      final wallpaper = File(p.join(tmp.path, 'wallpaper.gif'))
        ..writeAsBytesSync(base64Decode(animatedGifBase64));
      final dropzone = File(p.join(tmp.path, 'dropzone.gif'))
        ..writeAsBytesSync(base64Decode(animatedGifBase64));
      final font = File(p.join(tmp.path, 'MyFont.ttf'))
        ..writeAsBytesSync(List<int>.generate(2048, (i) => i % 256));
      final icons = Directory(p.join(tmp.path, 'icons'))..createSync();
      for (final tab in ['home', 'tools', 'settings']) {
        File(p.join(icons.path, '$tab.png'))
            .writeAsBytesSync(const [137, 80, 78, 71]);
      }
      // A non-tab file must be ignored by the packer.
      File(p.join(icons.path, 'bogus.png')).writeAsBytesSync(const [1, 2, 3]);

      final out = File(p.join(tmp.path, 'full.orskin'));
      final exported = manager.exportSkin(
        theme: sampleTheme(),
        outputPath: out,
        wallpaper: wallpaper,
        dropzone: dropzone,
        font: font,
        iconsDir: icons,
        author: 'M5 Dev',
        version: '2.0.0',
      );
      expect(exported.isOk, isTrue, reason: exported.error);

      // The archive must contain the canonical v2 entries.
      final names = ZipDecoder()
          .decodeBytes(out.readAsBytesSync())
          .map((e) => e.name)
          .toSet();
      expect(
          names,
          containsAll(<String>[
            'skin.json',
            'wallpaper.gif',
            'dropzone.gif',
            'font.ttf',
            'icons/home.png',
            'icons/tools.png',
            'icons/settings.png',
          ]));
      expect(names.contains('icons/bogus.png'), isFalse);

      // Import and verify every asset is resolved onto the theme.
      final imported = await manager.importSkin(out);
      expect(imported.isOk, isTrue, reason: imported.error);
      final skin = imported.value!;
      final theme = skin.theme;

      expect(skin.hasCustomFont, isTrue);
      expect(skin.fontFileName, 'font.ttf');
      expect(skin.hasCustomIcons, isTrue);
      expect(skin.hasCustomDropzone, isTrue);

      expect(theme.wallpaperPath, isNotNull);
      expect(theme.wallpaperPath, endsWith('wallpaper.gif'));
      expect(theme.dropzonePath, endsWith('dropzone.gif'));
      expect(theme.fontPath, endsWith('font.ttf'));
      expect(theme.iconDir, isNotNull);
      expect(File(theme.fontPath!).lengthSync(), 2048);
      expect(
        File(p.join(theme.iconDir!, 'home.png')).existsSync(),
        isTrue,
      );
    });

    test('export is deterministic for identical inputs', () async {
      final wallpaper = File(p.join(tmp.path, 'wallpaper.gif'))
        ..writeAsBytesSync(base64Decode(animatedGifBase64));
      final a = File(p.join(tmp.path, 'a.orskin'));
      final b = File(p.join(tmp.path, 'b.orskin'));

      manager.exportSkin(
        theme: sampleTheme(),
        outputPath: a,
        wallpaper: wallpaper,
      );
      manager.exportSkin(
        theme: sampleTheme(),
        outputPath: b,
        wallpaper: wallpaper,
      );

      expect(a.readAsBytesSync(), equals(b.readAsBytesSync()));
    });

    test('round-trips a GIF wallpaper through export/import', () async {
      final wallpaper = File(p.join(tmp.path, 'wallpaper.gif'))
        ..writeAsBytesSync(base64Decode(animatedGifBase64));
      final out = File(p.join(tmp.path, 'anim.orskin'));

      manager.exportSkin(
        theme: sampleTheme(),
        outputPath: out,
        wallpaper: wallpaper,
      );
      final imported = await manager.importSkin(out);

      final path = imported.value!.theme.wallpaperPath;
      expect(path, endsWith('.gif'));
      // Bytes preserved exactly, so the animation survives the round-trip.
      expect(
        File(path!).readAsBytesSync(),
        equals(base64Decode(animatedGifBase64)),
      );
    });

    test('accepts a legacy v1 theme.json bundle', () async {
      final archive = Archive();
      final json = utf8.encode(jsonEncode({
        'id': 'legacy-v1',
        'name': 'Legacy V1',
        'author': 'Old',
        'version': '1.0.0',
        'mode': 'dark',
        'borderRadius': 10.0,
        'wallpaperOpacity': 0.3,
        'wallpaperBlur': 1.0,
        'colors': {
          'background': '#101010',
          'surface': '#181818',
          'card': '#202020',
          'accent': '#abcdef',
          'text': '#ffffff',
          'textMuted': '#888888',
        },
      }));
      archive.addFile(ArchiveFile('theme.json', json.length, json));
      final out = File(p.join(tmp.path, 'v1.orskin'))
        ..writeAsBytesSync(ZipEncoder().encode(archive)!);

      final imported = await manager.importSkin(out);
      expect(imported.isOk, isTrue, reason: imported.error);
      expect(imported.value!.id, 'legacy-v1');
      expect(imported.value!.theme.borderRadius, 10.0);
      expect(imported.value!.hasCustomFont, isFalse);
      // Installed under the id, listed, and re-loadable.
      expect(manager.listInstalledSkins().single.id, 'legacy-v1');
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
