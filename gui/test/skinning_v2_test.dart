// OpenROM — .orskin v2 runtime skinning tests
// M5 Dev | GPL v3

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gui/l10n/app_localizations.dart';
import 'package:gui/models/theme_config.dart';
import 'package:gui/services/skin_manager.dart';
import 'package:gui/services/theme_service.dart';
import 'package:gui/widgets/drop_zone.dart';
import 'package:gui/widgets/sidebar.dart';
import 'package:gui/widgets/wallpaper_background.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

/// A 1x1 PNG — the smallest image that decodes cleanly.
const _tinyPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR42mP8z8BQDwAEhQGA'
    'hKmMIQAAAABJRU5ErkJggg==';

/// A 1x1 two-frame animated GIF.
const _animatedGifBase64 =
    'R0lGODlhAQABAIAAAAAAAP///yH/C05FVFNDQVBFMi4wAwEAAAAh+QQJBwAAACwAAAAAAQAB'
    'AAACAkQAACH5BAkHAAAALAAAAAABAAEAAAICRAAAOw==';

/// Locates a real, loadable font shipped with the Flutter test assets or SDK.
String? _findRealFont() {
  final candidates = <String>[
    'build/unit_test_assets/fonts/MaterialIcons-Regular.otf',
    'build/flutter_assets/fonts/MaterialIcons-Regular.otf',
  ];
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root != null) {
    candidates.add(
      p.join(
          root,
          'bin/cache/artifacts/material_fonts/'
          'MaterialIcons-Regular.otf'),
    );
  }
  for (final c in candidates) {
    if (File(c).existsSync()) return c;
  }
  return null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  late SkinManager manager;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    tmp = Directory.systemTemp.createTempSync('skinning_v2_test');
    manager = SkinManager(configDir: tmp);
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  Widget wrap(Widget child) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  group('pillar A — dynamic runtime fonts', () {
    test('loadSkinFont registers a real font and flips resolvedFontFamily',
        () async {
      final fontPath = _findRealFont();
      if (fontPath == null) {
        markTestSkipped('no bundled font available to load');
        return;
      }
      final service = ThemeService(skinManager: manager);
      final theme = ThemeConfig.defaultTheme().copyWith(fontPath: fontPath);

      expect(service.hasLoadedSkinFont, isFalse);
      await service.setTheme(theme);

      expect(service.hasLoadedSkinFont, isTrue);
      expect(service.resolvedFontFamily, ThemeService.skinFontFamily);
    });

    test('a missing font file degrades cleanly without throwing', () async {
      final service = ThemeService(skinManager: manager);
      final theme = ThemeConfig.defaultTheme()
          .copyWith(fontPath: p.join(tmp.path, 'does-not-exist.ttf'));

      await service.setTheme(theme);

      expect(service.hasLoadedSkinFont, isFalse);
      expect(service.resolvedFontFamily, theme.fontFamily);
    });

    test('clearing the font restores the theme family', () async {
      final fontPath = _findRealFont();
      if (fontPath == null) {
        markTestSkipped('no bundled font available to load');
        return;
      }
      final service = ThemeService(skinManager: manager);
      await service.setTheme(ThemeConfig.defaultTheme().copyWith(
        fontPath: fontPath,
      ));
      expect(service.hasLoadedSkinFont, isTrue);

      await service
          .setTheme(ThemeConfig.defaultTheme().copyWith(clearFont: true));

      expect(service.hasLoadedSkinFont, isFalse);
      expect(service.resolvedFontFamily, ThemeConfig.defaultTheme().fontFamily);
    });

    test('loadSkinFont returns false for an empty file', () async {
      final empty = File(p.join(tmp.path, 'empty.ttf'))..createSync();
      final service = ThemeService(skinManager: manager);
      expect(await service.loadSkinFont(empty), isFalse);
    });
  });

  group('pillar B — animated GIF wallpapers & dropzones', () {
    testWidgets('DropzoneArtwork renders GIF artwork when a skin sets one',
        (tester) async {
      final gif = File(p.join(tmp.path, 'dropzone.gif'))
        ..writeAsBytesSync(base64Decode(_animatedGifBase64));
      final theme = ThemeConfig.defaultTheme().copyWith(dropzonePath: gif.path);

      await tester.pumpWidget(wrap(DropzoneArtwork(theme: theme)));
      expect(find.byType(Image), findsOneWidget);
      expect(find.byIcon(kDefaultDropzoneIcon), findsNothing);
    });

    testWidgets('DropzoneArtwork falls back to the built-in icon',
        (tester) async {
      await tester.pumpWidget(
        wrap(DropzoneArtwork(theme: ThemeConfig.defaultTheme())),
      );
      expect(find.byIcon(kDefaultDropzoneIcon), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('DropzoneArtwork tolerates a stale artwork path',
        (tester) async {
      final theme = ThemeConfig.defaultTheme()
          .copyWith(dropzonePath: p.join(tmp.path, 'gone.gif'));
      await tester.pumpWidget(wrap(DropzoneArtwork(theme: theme)));
      expect(find.byIcon(kDefaultDropzoneIcon), findsOneWidget);
    });

    testWidgets('WallpaperBackground paints an animated GIF wallpaper',
        (tester) async {
      final gif = File(p.join(tmp.path, 'wallpaper.gif'))
        ..writeAsBytesSync(base64Decode(_animatedGifBase64));
      final theme = ThemeConfig.defaultTheme().copyWith(
        wallpaperPath: gif.path,
        wallpaperOpacity: 0.5,
      );

      await tester.pumpWidget(wrap(WallpaperBackground(
        theme: theme,
        child: const SizedBox.expand(),
      )));

      // A single Image paints the wallpaper; Image.file decodes the GIF frames.
      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(Opacity), findsOneWidget);
    });

    testWidgets('WallpaperBackground degrades to the flat colour when missing',
        (tester) async {
      final theme = ThemeConfig.defaultTheme()
          .copyWith(wallpaperPath: p.join(tmp.path, 'gone.gif'));
      await tester.pumpWidget(wrap(WallpaperBackground(
        theme: theme,
        child: const SizedBox.expand(),
      )));
      expect(find.byType(Image), findsNothing);
      expect(find.byType(ColoredBox), findsWidgets);
    });
  });

  group('pillar C — custom icon packs', () {
    testWidgets('Sidebar uses icons/<tab>.png overrides when present',
        (tester) async {
      final icons = Directory(p.join(tmp.path, 'icons'))..createSync();
      File(p.join(icons.path, 'home.png'))
          .writeAsBytesSync(base64Decode(_tinyPngBase64));
      final theme = ThemeConfig.defaultTheme().copyWith(iconDir: icons.path);

      await tester.pumpWidget(wrap(Sidebar(
        selectedIndex: 0,
        onDestinationSelected: (_) {},
        theme: theme,
      )));

      // Exactly one custom icon (home) is present; everything else stays a
      // Material icon.
      expect(find.byType(Image), findsOneWidget);
      expect(find.byIcon(Icons.queue_music), findsNothing);
      expect(find.byIcon(Icons.construction_outlined), findsOneWidget);
    });

    testWidgets('Sidebar falls back to Material icons without an icon pack',
        (tester) async {
      await tester.pumpWidget(wrap(Sidebar(
        selectedIndex: 0,
        onDestinationSelected: (_) {},
        theme: ThemeConfig.defaultTheme(),
      )));
      expect(find.byType(Image), findsNothing);
      expect(find.byIcon(Icons.queue_music), findsOneWidget);
    });
  });

  group('pillar D — modular navigation', () {
    testWidgets('Sidebar hides tabs listed in hiddenTabs', (tester) async {
      final theme = ThemeConfig.defaultTheme()
          .copyWith(hiddenTabs: const ['dreamcast', 'about']);

      await tester.pumpWidget(wrap(Sidebar(
        selectedIndex: 0,
        onDestinationSelected: (_) {},
        theme: theme,
      )));

      expect(find.byIcon(Icons.sports_esports_outlined), findsNothing);
      expect(find.byIcon(Icons.info_outline), findsNothing);
      // Remaining tabs are still present.
      expect(find.byIcon(Icons.queue_music), findsOneWidget);
      expect(find.byIcon(Icons.construction_outlined), findsOneWidget);
      expect(find.byIcon(Icons.palette), findsOneWidget);
    });

    testWidgets('Sidebar reports the absolute screen index on tap',
        (tester) async {
      final theme = ThemeConfig.defaultTheme()
          .copyWith(hiddenTabs: const ['patcher', 'tools']);
      int? tapped;
      await tester.pumpWidget(wrap(Sidebar(
        selectedIndex: 0,
        onDestinationSelected: (i) => tapped = i,
        theme: theme,
      )));

      await tester.tap(find.byIcon(Icons.palette));
      // 'theme' is tab index 7 even though two earlier tabs are hidden.
      expect(tapped, 7);
    });

    test('hiddenTabs survives an export/import round-trip', () async {
      final theme = ThemeConfig.defaultTheme().copyWith(
        name: 'Modular',
        hiddenTabs: const ['dreamcast', 'plugins'],
      );
      final out = File(p.join(tmp.path, 'modular.orskin'));
      expect(manager.exportSkin(theme: theme, outputPath: out).isOk, isTrue);

      final imported = await manager.importSkin(out);
      expect(imported.value!.hiddenTabs, ['dreamcast', 'plugins']);
      expect(imported.value!.theme.hiddenTabs, ['dreamcast', 'plugins']);
    });
  });

  group('end-to-end v2 bundle', () {
    test('a full bundle imports with every pillar resolved', () async {
      final fontPath = _findRealFont();
      final wallpaper = File(p.join(tmp.path, 'wallpaper.gif'))
        ..writeAsBytesSync(base64Decode(_animatedGifBase64));
      final dropzone = File(p.join(tmp.path, 'dropzone.gif'))
        ..writeAsBytesSync(base64Decode(_animatedGifBase64));
      final icons = Directory(p.join(tmp.path, 'icons'))..createSync();
      File(p.join(icons.path, 'home.png'))
          .writeAsBytesSync(base64Decode(_tinyPngBase64));

      final theme = ThemeConfig.defaultTheme().copyWith(
        name: 'Full Skin',
        hiddenTabs: const ['about'],
      );
      final out = File(p.join(tmp.path, 'full.orskin'));
      final exported = manager.exportSkin(
        theme: theme,
        outputPath: out,
        wallpaper: wallpaper,
        dropzone: dropzone,
        font: fontPath == null ? null : File(fontPath),
        iconsDir: icons,
      );
      expect(exported.isOk, isTrue, reason: exported.error);

      final service = ThemeService(skinManager: manager);
      final imported = await service.importSkin(out);
      expect(imported.isOk, isTrue, reason: imported.error);

      final skin = imported.value!;
      expect(skin.theme.hiddenTabs, ['about']);
      expect(skin.theme.dropzonePath, endsWith('dropzone.gif'));
      expect(skin.theme.iconDir, isNotNull);
      expect(skin.theme.wallpaperPath, endsWith('wallpaper.gif'));
      if (fontPath != null) {
        expect(skin.hasCustomFont, isTrue);
        expect(service.hasLoadedSkinFont, isTrue);
      }
    });
  });
}
