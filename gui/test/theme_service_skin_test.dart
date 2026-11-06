// OpenROM — ThemeService <-> SkinManager integration tests
// M5 Dev | GPL v3

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gui/models/theme_config.dart';
import 'package:gui/services/skin_manager.dart';
import 'package:gui/services/theme_service.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  late SkinManager manager;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    tmp = Directory.systemTemp.createTempSync('theme_service_test');
    manager = SkinManager(configDir: tmp);
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  test('importSkin applies the palette and lists it as available', () async {
    final theme = ThemeConfig.defaultTheme().copyWith(
      name: 'Vaporwave',
      accent: const Color(0xff7b5cff),
      borderRadius: 20,
    );
    final bundle = File(p.join(tmp.path, 'vaporwave.orskin'));
    expect(
      manager.exportSkin(theme: theme, outputPath: bundle).isOk,
      isTrue,
    );

    final service = ThemeService(skinManager: manager);
    await service.init();

    final result = await service.importSkin(bundle);
    expect(result.isOk, isTrue, reason: result.error);
    expect(service.currentTheme.name, 'Vaporwave');
    expect(service.currentTheme.accent, const Color(0xff7b5cff));
    expect(
      service.availableThemes.any((t) => t.name == 'Vaporwave'),
      isTrue,
    );
  });

  test('importSkin surfaces errors without changing the theme', () async {
    final service = ThemeService(skinManager: manager);
    await service.init();
    final before = service.currentTheme.name;

    final result = await service.importSkin(
      File(p.join(tmp.path, 'missing.orskin')),
    );
    expect(result.isOk, isFalse);
    expect(service.currentTheme.name, before);
  });

  test('exportSkin writes a bundle that reloads as an installed skin',
      () async {
    final service = ThemeService(skinManager: manager);
    await service.init();

    final out = File(p.join(tmp.path, 'exported.orskin'));
    final exported = service.exportSkin(
      theme: ThemeConfig.defaultTheme().copyWith(name: 'Exported'),
      outputPath: out,
    );
    expect(exported.isOk, isTrue, reason: exported.error);

    await manager.importSkin(out);
    expect(
      manager.listInstalledSkins().map((s) => s.theme.name),
      contains('Exported'),
    );
  });
}
