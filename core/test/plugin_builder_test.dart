// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:openrom_core/openrom_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late OrplugBuilder builder;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('openrom_builder_test_');
    builder = OrplugBuilder(coreVersion: const SemVer(3, 9, 0));
  });

  tearDown(() {
    try {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  String sha256Hex(List<int> bytes) => sha256.convert(bytes).toString();

  group('OrplugBuilder.init', () {
    test('scaffolds a complete starter plugin folder', () {
      final target = p.join(tempDir.path, 'my-tool');
      final res = builder.init(target, name: 'My Tool', id: 'my-tool');

      expect(res.success, isTrue, reason: res.error);
      expect(File(p.join(target, 'plugin.json')).existsSync(), isTrue);
      expect(File(p.join(target, 'README.md')).existsSync(), isTrue);
      expect(File(p.join(target, 'LICENSE')).existsSync(), isTrue);
      expect(File(p.join(target, 'icon.png')).existsSync(), isTrue);
      for (final d in const [
        'bin/windows/x86_64',
        'bin/linux/x86_64',
        'bin/macos/arm64',
      ]) {
        expect(Directory(p.join(target, d)).existsSync(), isTrue, reason: d);
      }

      final manifest = jsonDecode(
        File(p.join(target, 'plugin.json')).readAsStringSync(),
      ) as Map<String, dynamic>;
      expect(manifest['id'], 'my-tool');
      expect(manifest['name'], 'My Tool');
      expect(manifest['version'], '1.0.0');
      expect(manifest['minCoreVersion'], '3.9.0');
      expect(manifest['schemaVersion'], 2);
    });

    test('derives the id from the folder name when none is given', () {
      final target = p.join(tempDir.path, 'My Cool Tool');
      final res = builder.init(target, name: 'My Cool Tool');
      expect(res.success, isTrue, reason: res.error);
      expect(res.manifest!.id, 'my-cool-tool');
    });

    test('refuses to overwrite an existing plugin.json', () {
      final target = p.join(tempDir.path, 'dup');
      expect(builder.init(target, id: 'dup').success, isTrue);
      final second = builder.init(target, id: 'dup');
      expect(second.success, isFalse);
      expect(second.error, contains('already exists'));
    });
  });

  group('OrplugBuilder.validate', () {
    test('flags a missing plugin.json', () {
      final empty = Directory(p.join(tempDir.path, 'empty'))..createSync();
      final res = builder.validate(empty.path);
      expect(res.success, isFalse);
      expect(res.errors.join(), contains('plugin.json'));
    });

    test('warns (but does not fail) when binaries are absent', () {
      final target = p.join(tempDir.path, 'warn');
      builder.init(target, id: 'warn');
      final res = builder.validate(target);
      expect(res.success, isTrue, reason: res.errors.join('|'));
      expect(res.warnings, isNotEmpty);
    });

    test('detects a SHA-256 mismatch in a folder', () {
      final target = p.join(tempDir.path, 'mismatch');
      builder.init(target, id: 'mismatch');
      final bin = File(p.join(target, 'bin/linux/x86_64/mismatch'))
        ..writeAsBytesSync(utf8.encode('real-binary'));

      // Inject a bogus hash for the linux binary.
      final manifestFile = File(p.join(target, 'plugin.json'));
      final manifest =
          jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      final envs = (manifest['execution']
          as Map<String, dynamic>)['environments'] as Map<String, dynamic>;
      (envs['linux_x64'] as Map<String, dynamic>)['sha256'] = 'a' * 64;
      manifestFile.writeAsStringSync(jsonEncode(manifest));

      final res = builder.validate(target);
      expect(res.success, isFalse);
      expect(res.errors.join(), contains('SHA-256 mismatch'));
      expect(bin.existsSync(), isTrue);
    });

    test('rejects an executable that escapes the plugin folder', () {
      final target = p.join(tempDir.path, 'escape');
      builder.init(target, id: 'escape');
      final manifestFile = File(p.join(target, 'plugin.json'));
      final manifest =
          jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      final envs = (manifest['execution']
          as Map<String, dynamic>)['environments'] as Map<String, dynamic>;
      (envs['linux_x64'] as Map<String, dynamic>)['executable'] = '../../evil';
      manifestFile.writeAsStringSync(jsonEncode(manifest));

      final res = builder.validate(target);
      expect(res.success, isFalse);
      expect(res.errors.join(), contains('relative path'));
    });

    test('rejects zip-slip inside an archive', () {
      final archivePath = p.join(tempDir.path, 'slip.orplug');
      final encoder = ZipFileEncoder()..create(archivePath);
      final manifest = {
        'schemaVersion': 2,
        'id': 'slip',
        'name': 'Slip',
        'version': '1.0.0',
        'minCoreVersion': '3.9.0',
        'publisher': {'id': 'p', 'name': 'P'},
        'execution': {
          'environments': {
            'linux_x64': {'executable': 'bin/tool', 'sha256': 'a' * 64},
          },
          'args': [
            {'kind': 'executable'},
          ],
        },
      };
      final mf = File(p.join(tempDir.path, '_plugin.json'))
        ..writeAsStringSync(jsonEncode(manifest));
      encoder.addFile(mf, 'plugin.json');
      final evil = File(p.join(tempDir.path, '_evil'))
        ..writeAsStringSync('pwned');
      encoder.addFile(evil, '../escape.txt');
      encoder.closeSync();

      final res = builder.validate(archivePath);
      expect(res.success, isFalse);
      expect(res.errors.join(), contains('Zip-Slip'));
    });
  });

  group('OrplugBuilder.pack (end-to-end)', () {
    test('hashes binaries, validates, packages and emits a marketplace entry',
        () async {
      final target = p.join(tempDir.path, 'e2e-tool');
      expect(builder.init(target, name: 'E2E Tool', id: 'e2e-tool').success,
          isTrue);

      const content = '#!/bin/sh\necho hi\n';
      File(p.join(target, 'bin/linux/x86_64/e2e-tool'))
          .writeAsStringSync(content);
      final win = File(p.join(target, 'bin/windows/x86_64/e2e-tool.exe'))
        ..writeAsBytesSync(utf8.encode('windows-binary'));
      final mac = File(p.join(target, 'bin/macos/arm64/e2e-tool'))
        ..writeAsBytesSync(utf8.encode('mac-binary'));

      final res = builder.pack(target);

      expect(res.success, isTrue, reason: res.error);
      expect(res.outputPath, endsWith('e2e-tool-1.0.0.orplug'));
      expect(File(res.outputPath!).existsSync(), isTrue);
      expect(res.archiveSha256, matches(RegExp(r'^[0-9a-f]{64}$')));

      // The manifest on disk now carries the real digests.
      final injected = jsonDecode(
        File(p.join(target, 'plugin.json')).readAsStringSync(),
      ) as Map<String, dynamic>;
      final envs = (injected['execution']
          as Map<String, dynamic>)['environments'] as Map<String, dynamic>;
      expect((envs['linux_x64'] as Map<String, dynamic>)['sha256'],
          sha256Hex(utf8.encode(content)));
      expect((envs['windows_x64'] as Map<String, dynamic>)['sha256'],
          sha256Hex(win.readAsBytesSync()));
      expect((envs['macos_arm64'] as Map<String, dynamic>)['sha256'],
          sha256Hex(mac.readAsBytesSync()));

      // Marketplace entry is well-formed.
      final entry = res.marketplaceEntry!;
      expect(entry['id'], 'e2e-tool');
      expect(entry['publisherId'], 'your-publisher-id');
      final stable =
          (entry['channels'] as Map<String, dynamic>)['stable'] as Map;
      final artifacts = stable['artifacts'] as Map;
      expect(artifacts.keys, containsAll(['linux_x64', 'windows_x64']));
      expect((artifacts['linux_x64'] as Map)['sha256'], res.archiveSha256);

      // The archive itself validates cleanly.
      final validation = builder.validate(res.outputPath!);
      expect(validation.success, isTrue, reason: validation.errors.join('|'));

      // And it installs through the real installer.
      PluginManager.instance
          .setCustomPluginsDir(p.join(tempDir.path, 'installed'));
      PluginManager.instance.setCoreVersionOverride(const SemVer(3, 9, 0));
      addTearDown(() {
        PluginManager.instance.setCustomPluginsDir(null);
        PluginManager.instance.setCoreVersionOverride(null);
        PluginRegistry.instance.clear();
      });

      final install =
          await PluginManager.instance.installPluginDetailed(res.outputPath!);
      expect(install.success, isTrue, reason: install.error);
      expect(PluginManager.instance.installedPlugins.single.id, 'e2e-tool');
    });

    test('fails when the manifest is invalid', () {
      final target = p.join(tempDir.path, 'bad');
      builder.init(target, id: 'bad');
      final manifestFile = File(p.join(target, 'plugin.json'));
      final manifest =
          jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      manifest['version'] = 'not-a-semver';
      manifestFile.writeAsStringSync(jsonEncode(manifest));

      final res = builder.pack(target);
      expect(res.success, isFalse);
      expect(res.error, contains('validation failed'));
    });

    test('honours an explicit --out path', () {
      final target = p.join(tempDir.path, 'out-test');
      builder.init(target, id: 'out-test');
      File(p.join(target, 'bin/linux/x86_64/out-test'))
          .writeAsStringSync('bin');

      final out = p.join(tempDir.path, 'custom.orplug');
      final res = builder.pack(target, outputPath: out);
      expect(res.success, isTrue, reason: res.error);
      expect(res.outputPath, out);
      expect(File(out).existsSync(), isTrue);
    });
  });
}
