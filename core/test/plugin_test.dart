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

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('openrom_plugin_test_');
    PluginManager.instance.setCustomPluginsDir(p.join(tempDir.path, 'plugins'));
    PluginRegistry.instance.clear();
  });

  tearDown(() {
    PluginRegistry.instance.clear();
    PluginManager.instance.setCustomPluginsDir(null);
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('PluginManifest Schema Parsing & Validation', () {
    test('parses valid manifest JSON correctly', () {
      final jsonMap = {
        'id': 'xbox360-tools',
        'name': 'Xbox 360 Plugin',
        'version': '1.0.0',
        'author': 'OpenROM Team',
        'description': 'Plugin for Xbox 360 images',
        'minCoreVersion': '3.9.0',
        'binaries': {
          'windows_x64': {
            'executable': 'bin/tool.exe',
            'sha256':
                '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
          },
          'linux_x64': {
            'executable': 'bin/tool',
            'sha256':
                'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
          },
        },
        'extensions': [
          {
            'ext': '.zar',
            'format': 'ZAR',
            'platform': 'Xbox 360',
            'color': '#388e3c',
          }
        ],
        'conversions': [
          {
            'from': 'ISO',
            'to': 'ZAR',
            'command': '{bin} pack "{in}" "{out}"',
          }
        ],
      };

      final manifest = PluginManifest.fromJson(jsonMap);
      expect(manifest.id, equals('xbox360-tools'));
      expect(manifest.name, equals('Xbox 360 Plugin'));
      expect(manifest.version, equals('1.0.0'));
      expect(manifest.binaries.length, equals(2));
      expect(
          manifest.binaries['windows_x64']?.executable, equals('bin/tool.exe'));
      expect(manifest.extensions.length, equals(1));
      expect(manifest.extensions.first.format, equals('ZAR'));
      expect(manifest.conversions.length, equals(1));
      expect(manifest.conversions.first.command,
          equals('{bin} pack "{in}" "{out}"'));

      final errors = manifest.validate();
      expect(errors, isEmpty);
    });

    test('validates invalid manifest missing required fields', () {
      final manifest = PluginManifest.fromJson({});
      final errors = manifest.validate();
      expect(errors, isNotEmpty);
      expect(errors, contains('Plugin "id" is required.'));
      expect(errors, contains('Plugin "name" is required.'));
      expect(errors, contains('Plugin "version" is required.'));
      expect(errors, contains('Plugin "minCoreVersion" is required.'));
    });

    test('validates invalid plugin ID format', () {
      final manifest = PluginManifest.fromJson({
        'id': 'invalid id with spaces!',
        'name': 'Test',
        'version': '1.0.0',
        'minCoreVersion': '3.9.0',
      });
      final errors = manifest.validate();
      expect(
          errors,
          contains(
              'Plugin "id" must contain only alphanumeric characters, underscores, or hyphens.'));
    });
  });

  group('Plugin Installation, Extraction, and SHA256 Verification', () {
    test(
        'installs valid .orplug ZIP archive and verifies platform binary SHA256',
        () async {
      final platKey = getCurrentPlatformKey();
      final dummyBinContent = 'mock_binary_executable_content_123';
      final dummyBinDigest =
          sha256.convert(utf8.encode(dummyBinContent)).toString();

      final manifestJson = {
        'id': 'test-plugin',
        'name': 'Test Dynamic Plugin',
        'version': '1.2.3',
        'author': 'Tester',
        'description': 'A mock test plugin',
        'minCoreVersion': '3.9.0',
        'binaries': {
          platKey: {
            'executable': 'test_tool',
            'sha256': dummyBinDigest,
          }
        },
        'extensions': [
          {
            'ext': '.mock',
            'format': 'MOCK',
            'platform': 'Mock Console',
            'color': '#ff00ff',
          }
        ],
        'conversions': [
          {
            'from': 'ISO',
            'to': 'MOCK',
            'command': '"{bin}" convert "{in}" "{out}"',
          }
        ],
      };

      // Create ZIP archive (.orplug)
      final encoder = ZipFileEncoder();
      final orplugPath = p.join(tempDir.path, 'test_plugin.orplug');
      encoder.create(orplugPath);

      final manifestFile = File(p.join(tempDir.path, 'plugin.json'))
        ..writeAsStringSync(jsonEncode(manifestJson));
      final binFile = File(p.join(tempDir.path, 'test_tool'))
        ..writeAsStringSync(dummyBinContent);

      encoder.addFile(manifestFile, 'plugin.json');
      encoder.addFile(binFile, 'test_tool');
      encoder.close();

      final installed = await PluginManager.instance.installPlugin(orplugPath);
      expect(installed, isTrue);

      final activePlugins = PluginManager.instance.installedPlugins;
      expect(activePlugins.length, equals(1));
      expect(activePlugins.first.id, equals('test-plugin'));

      // Check dynamic registry updates
      expect(supportedInput['.mock'], equals('MOCK'));
      expect(platformMap['MOCK'], equals('Mock Console'));
      expect(formatColors['MOCK'], equals('#ff00ff'));
      expect(getValidTargets('ISO'), contains('MOCK'));

      final cmdPreview = getCommandPreview('ISO', 'MOCK', 'game.iso');
      expect(cmdPreview, equals('"{bin}" convert "game.iso" "game.mock"'));

      // Test uninstall
      final uninstalled =
          await PluginManager.instance.uninstallPlugin('test-plugin');
      expect(uninstalled, isTrue);
      expect(PluginManager.instance.installedPlugins, isEmpty);
      expect(supportedInput.containsKey('.mock'), isFalse);
    });

    test('refuses installation when SHA256 checksum mismatches', () async {
      final platKey = getCurrentPlatformKey();
      final manifestJson = {
        'id': 'corrupt-plugin',
        'name': 'Corrupt Plugin',
        'version': '1.0.0',
        'author': 'Tester',
        'description': 'SHA mismatch plugin',
        'minCoreVersion': '3.9.0',
        'binaries': {
          platKey: {
            'executable': 'test_tool',
            'sha256':
                'bad_sha256_checksum_000000000000000000000000000000000000000000000',
          }
        },
        'extensions': [],
        'conversions': [],
      };

      final encoder = ZipFileEncoder();
      final orplugPath = p.join(tempDir.path, 'corrupt.orplug');
      encoder.create(orplugPath);

      final manifestFile = File(p.join(tempDir.path, 'plugin.json'))
        ..writeAsStringSync(jsonEncode(manifestJson));
      final binFile = File(p.join(tempDir.path, 'test_tool'))
        ..writeAsStringSync('dummy content');

      encoder.addFile(manifestFile, 'plugin.json');
      encoder.addFile(binFile, 'test_tool');
      encoder.close();

      final installed = await PluginManager.instance.installPlugin(orplugPath);
      expect(installed, isFalse);
      expect(PluginManager.instance.installedPlugins, isEmpty);
    });
  });

  group('Converter `{bin}` Path Resolution & Plugin Execution', () {
    test('resolves `{bin}` to absolute path during plugin conversion',
        () async {
      final platKey = getCurrentPlatformKey();
      final scriptName = Platform.isWindows ? 'mock_tool.bat' : 'mock_tool.sh';
      final scriptContent = Platform.isWindows
          ? '@echo off\r\necho Converting %2 to %3\r\nexit 0\r\n'
          : '#!/bin/sh\necho "Converting \$2 to \$3"\nexit 0\n';

      final scriptDigest =
          sha256.convert(utf8.encode(scriptContent)).toString();

      final manifestJson = {
        'id': 'script-plugin',
        'name': 'Script Tool Plugin',
        'version': '2.0.0',
        'author': 'OpenROM',
        'description': 'Script based converter',
        'minCoreVersion': '3.9.0',
        'binaries': {
          platKey: {
            'executable': scriptName,
            'sha256': scriptDigest,
          }
        },
        'extensions': [
          {
            'ext': '.srcfmt',
            'format': 'SRCFMT',
            'platform': 'Custom System',
            'color': '#123456',
          }
        ],
        'conversions': [
          {
            'from': 'SRCFMT',
            'to': 'TGTFMT',
            'command': '"{bin}" convert "{in}" "{out}"',
          }
        ],
      };

      final encoder = ZipFileEncoder();
      final orplugPath = p.join(tempDir.path, 'script.orplug');
      encoder.create(orplugPath);

      final manifestFile = File(p.join(tempDir.path, 'plugin.json'))
        ..writeAsStringSync(jsonEncode(manifestJson));
      final scriptFile = File(p.join(tempDir.path, scriptName))
        ..writeAsStringSync(scriptContent);

      encoder.addFile(manifestFile, 'plugin.json');
      encoder.addFile(scriptFile, scriptName);
      encoder.close();

      final installed = await PluginManager.instance.installPlugin(orplugPath);
      expect(installed, isTrue);

      final dummyInput = File(p.join(tempDir.path, 'sample.srcfmt'))
        ..writeAsStringSync('dummy input ROM');

      final job = ConversionJob(
        filepath: dummyInput.path,
        outputDir: tempDir.path,
        targetFormat: 'TGTFMT',
      );

      final converter = Converter();
      final success = await converter.convert(job);

      expect(success, isTrue);
      expect(job.status, equals('Done'));
    });
  });
}
