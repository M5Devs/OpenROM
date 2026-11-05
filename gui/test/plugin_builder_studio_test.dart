// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gui/controllers/plugin_builder_controller.dart';
import 'package:openrom_core/openrom_core.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;
  late PluginBuilderController controller;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('openrom_studio_test_');
    controller = PluginBuilderController(coreVersion: const SemVer(3, 9, 0));
  });

  tearDown(() {
    try {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  String sha256Hex(List<int> bytes) => sha256.convert(bytes).toString();

  /// Writes a fake binary at the canonical `bin/<os>/<arch>/` location.
  void writeBinary(
      String projectDir, String platformKey, String name, String content) {
    final binDir = studioBinDir(platformKey)!;
    final file = File(p.join(projectDir, binDir, name))
      ..createSync(recursive: true)
      ..writeAsStringSync(content);
    expect(file.existsSync(), isTrue);
  }

  group('Studio helpers', () {
    test('maps every platform key to a bin directory', () {
      for (final key in kStudioPlatformKeys) {
        expect(studioBinDir(key), isNotNull, reason: key);
      }
      expect(studioBinDir('linux_x64'), 'bin/linux/x86_64');
      expect(studioBinDir('macos_arm64'), 'bin/macos/arm64');
      expect(studioBinDir('windows_x64'), 'bin/windows/x86_64');
    });

    test('renders friendly platform labels', () {
      expect(PluginBuilderController.platformLabel('linux_x64'), 'Linux x64');
      expect(
          PluginBuilderController.platformLabel('macos_arm64'), 'macOS ARM64');
    });
  });

  group('Scaffold', () {
    test('creates a starter project via the core builder', () async {
      controller.setIdentity(id: 'studio-tool', name: 'Studio Tool');
      controller.setCategory('Nintendo');
      final dir = p.join(tempDir.path, 'studio-tool');

      expect(await controller.scaffold(dir), isTrue,
          reason: controller.errorMessage);
      expect(File(p.join(dir, 'plugin.json')).existsSync(), isTrue);
      expect(Directory(p.join(dir, 'bin/linux/x86_64')).existsSync(), isTrue);

      expect(controller.projectLoaded, isTrue);
      expect(controller.id, 'studio-tool');
      expect(controller.name, 'Studio Tool');
      expect(controller.category, 'Nintendo');
    });
  });

  group('Manifest persistence', () {
    test('saving injects the SHA-256 of each discovered binary', () async {
      final dir = p.join(tempDir.path, 'hash-tool');
      controller.setIdentity(id: 'hash-tool', name: 'Hash Tool');
      expect(await controller.scaffold(dir), isTrue);

      writeBinary(dir, 'linux_x64', 'hash-tool', 'linux-bytes');
      writeBinary(dir, 'windows_x64', 'hash-tool.exe', 'windows-bytes');
      await controller.refresh();

      expect(controller.binaries.length, 2);
      expect(await controller.saveManifest(), isTrue,
          reason: controller.errorMessage);

      final raw = jsonDecode(
        File(p.join(dir, 'plugin.json')).readAsStringSync(),
      ) as Map<String, dynamic>;
      final envs = (raw['execution'] as Map<String, dynamic>)['environments']
          as Map<String, dynamic>;

      expect((envs['linux_x64'] as Map)['sha256'],
          sha256Hex(utf8.encode('linux-bytes')));
      expect((envs['windows_x64'] as Map)['sha256'],
          sha256Hex(utf8.encode('windows-bytes')));
      expect((envs['linux_x64'] as Map)['executable'],
          'bin/linux/x86_64/hash-tool');
    });

    test('routes and args are written in the structured v2 form', () async {
      final dir = p.join(tempDir.path, 'routes-tool');
      controller.setIdentity(id: 'routes-tool', name: 'Routes Tool');
      expect(await controller.scaffold(dir), isTrue);

      writeBinary(dir, 'linux_x64', 'routes-tool', 'bin');
      await controller.refresh();

      controller.addRoute('ISO -> WUA');
      controller.addRoute('RVZ -> ISO');
      controller.setArgsTemplate('convert --input {in} --output {out}');
      expect(await controller.saveManifest(), isTrue,
          reason: controller.errorMessage);

      final raw = jsonDecode(
        File(p.join(dir, 'plugin.json')).readAsStringSync(),
      ) as Map<String, dynamic>;

      // The scaffold seeds one route (`ISO -> MYFMT`); ours are appended.
      final routes = (raw['routes'] as List).cast<Map<String, dynamic>>();
      expect(routes.any((r) => r['from'] == 'ISO' && r['to'] == 'WUA'), isTrue);
      expect(routes.any((r) => r['from'] == 'RVZ' && r['to'] == 'ISO'), isTrue);

      // `convert --input {in} --output {out}` → structured argv tokens.
      final args = (raw['execution'] as Map)['args'] as List;
      final kinds =
          args.map((a) => (a as Map<String, dynamic>)['kind']).toList();
      expect(kinds, ['literal', 'literal', 'input', 'literal', 'output']);
      expect((args.first as Map)['value'], 'convert');
      expect((args.last as Map)['kind'], 'output');
    });

    test('rejects an invalid SemVer on save', () async {
      final dir = p.join(tempDir.path, 'bad-ver');
      controller.setIdentity(id: 'bad-ver', name: 'Bad Ver');
      expect(await controller.scaffold(dir), isTrue);
      controller.setVersion('not-semver');

      expect(await controller.saveManifest(), isFalse);
      expect(controller.validation?.success, isFalse);
      expect(controller.errorMessage, isNotNull);
    });
  });

  group('Build', () {
    test('packs the project and exposes a marketplace entry', () async {
      final dir = p.join(tempDir.path, 'pack-tool');
      controller.setIdentity(id: 'pack-tool', name: 'Pack Tool');
      controller.setCategory('Utility');
      expect(await controller.scaffold(dir), isTrue);

      writeBinary(dir, 'linux_x64', 'pack-tool', '#!/bin/sh\necho hi\n');
      writeBinary(dir, 'windows_x64', 'pack-tool.exe', 'win-bin');
      writeBinary(dir, 'macos_arm64', 'pack-tool', 'mac-bin');
      await controller.refresh();

      expect(await controller.pack(), isTrue, reason: controller.errorMessage);

      final res = controller.packResult!;
      expect(res.success, isTrue);
      expect(controller.packOutputPath, endsWith('pack-tool-1.0.0.orplug'));
      expect(File(controller.packOutputPath!).existsSync(), isTrue);
      expect(res.archiveSha256, matches(RegExp(r'^[0-9a-f]{64}$')));

      // The emitted marketplace JSON parses and matches the storefront shape.
      final entry = jsonDecode(controller.marketplaceJson!);
      expect(entry['id'], 'pack-tool');
      expect(entry['category'], 'Utility');
      expect(entry['sha256'], res.archiveSha256);
      expect(entry['platforms'], containsAll(['Windows', 'Linux', 'macOS']));
      expect(entry['downloadUrl'], contains('pack-tool-1.0.0.orplug'));

      // And the produced archive validates cleanly.
      expect(controller.validation?.success, isTrue,
          reason: controller.validation?.errors.join('|'));
    });

    test('building is blocked until a project is loaded', () {
      expect(controller.projectLoaded, isFalse);
      expect(controller.canBuild, isFalse);
    });
  });

  group('Binary management', () {
    test('removeBinary deletes the platform directory', () async {
      final dir = p.join(tempDir.path, 'rm-tool');
      controller.setIdentity(id: 'rm-tool', name: 'RM Tool');
      expect(await controller.scaffold(dir), isTrue);
      writeBinary(dir, 'linux_x64', 'rm-tool', 'x');
      await controller.refresh();
      expect(controller.binaries.length, 1);

      await controller.removeBinary('linux_x64');
      expect(controller.binaries, isEmpty);
      expect(Directory(p.join(dir, 'bin/linux/x86_64')).existsSync(), isFalse);
    });

    test('openProject loads an existing manifest', () async {
      final dir = p.join(tempDir.path, 'load-tool');
      controller.setIdentity(id: 'load-tool', name: 'Load Tool');
      expect(await controller.scaffold(dir), isTrue);

      // Edit the manifest on disk, then load it into a fresh controller.
      final manifestFile = File(p.join(dir, 'plugin.json'));
      final raw =
          jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      raw['description'] = 'Edited on disk.';
      manifestFile.writeAsStringSync(jsonEncode(raw));

      final fresh = PluginBuilderController(coreVersion: const SemVer(3, 9, 0));
      await fresh.openProject(dir);

      expect(fresh.projectLoaded, isTrue);
      expect(fresh.id, 'load-tool');
      expect(fresh.name, 'Load Tool');
      expect(fresh.description, 'Edited on disk.');
    });
  });
}
