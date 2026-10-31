// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:openrom_core/openrom_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Builds a `.orplug` ZIP on disk from a set of `name -> content` entries.
String _writeOrplug(
  Directory dir,
  String fileName,
  Map<String, List<int>> entries,
) {
  final path = p.join(dir.path, fileName);
  final encoder = ZipFileEncoder();
  encoder.create(path);
  entries.forEach((name, bytes) {
    final tmp = File(p.join(dir.path, '_tmp_${name.replaceAll('/', '_')}'))
      ..writeAsBytesSync(bytes);
    encoder.addFile(tmp, name);
    tmp.deleteSync();
  });
  encoder.close();
  return path;
}

String _sha256(String content) =>
    sha256.convert(utf8.encode(content)).toString();

/// A valid schema-v2 manifest for the host platform.
Map<String, dynamic> _v2Manifest({
  String id = 'xbox360-tools',
  String version = '1.2.0',
  String minCore = '3.9.0',
  String executable = 'bin/tool',
  String? binaryContent,
  bool override = false,
  String from = 'SRCFMT',
  String to = 'TGTFMT',
}) {
  final content = binaryContent ?? 'mock-binary-$id';
  final platKey = currentPlatformKey();
  return {
    'schemaVersion': 2,
    'id': id,
    'name': 'Xbox 360 Tools',
    'version': version,
    'minCoreVersion': minCore,
    'description': 'Test plugin',
    'publisher': {'id': 'm5dev', 'name': 'M5 Dev', 'verified': true},
    'routes': [
      {'from': from, 'to': to, if (override) 'override': true}
    ],
    'execution': {
      'kind': 'process',
      'environments': {
        platKey: {'executable': executable, 'sha256': _sha256(content)}
      },
      'args': [
        {'kind': 'executable'},
        {'kind': 'literal', 'value': 'convert'},
        {'kind': 'input'},
        {'kind': 'output'},
      ],
    },
    'extensions': [
      {'ext': '.srcfmt', 'format': from, 'platform': 'Test', 'color': '#123456'}
    ],
  };
}

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('openrom_plugin_test_');
    PluginManager.instance.setCustomPluginsDir(p.join(tempDir.path, 'plugins'));
    PluginManager.instance.setCoreVersionOverride(const SemVer(3, 9, 0));
    PluginRegistry.instance.clear();
  });

  tearDown(() {
    PluginRegistry.instance.clear();
    PluginManager.instance.setCustomPluginsDir(null);
    PluginManager.instance.setCoreVersionOverride(null);
    try {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('SemVer', () {
    test('parses and orders versions correctly', () {
      expect(SemVer.tryParse('1.2.3'), const SemVer(1, 2, 3));
      expect(SemVer.tryParse('01.2.3'), isNull); // leading zero is invalid
      expect(SemVer.tryParse('1.2'), isNull);
      expect(SemVer.tryParseLoose('v3.9.0'), const SemVer(3, 9, 0));
      expect(SemVer.tryParseLoose('3.9'), const SemVer(3, 9, 0));

      expect(const SemVer(1, 0, 0) > const SemVer(0, 9, 9), isTrue);
      expect(
          const SemVer(1, 0, 0, preRelease: ['beta']) < const SemVer(1, 0, 0),
          isTrue);
      expect(
          const SemVer(1, 0, 0, preRelease: ['beta', '2']) >
              const SemVer(1, 0, 0, preRelease: ['beta', '1']),
          isTrue);
    });
  });

  group('PluginManifest v2 schema', () {
    test('parses structured manifest and validates cleanly', () {
      final manifest = PluginManifest.fromJson(_v2Manifest());
      expect(manifest.id, 'xbox360-tools');
      expect(manifest.version, const SemVer(1, 2, 0));
      expect(manifest.publisher.verified, isTrue);
      expect(manifest.routes.single.from, 'SRCFMT');
      expect(manifest.execution.args.length, 4);
      expect(manifest.validate(), isEmpty);
    });

    test('rejects invalid ids and unsafe binary paths', () {
      final bad = PluginManifest.fromJson({
        'schemaVersion': 2,
        'id': 'Bad Id!',
        'name': 'X',
        'version': '1.0.0',
        'minCoreVersion': '1.0.0',
        'publisher': {'id': 'p', 'name': 'P'},
        'routes': [
          {'from': 'A', 'to': 'B'}
        ],
        'execution': {
          'environments': {
            currentPlatformKey(): {
              'executable': '../../evil',
              'sha256': 'a' * 64
            }
          },
          'args': [
            {'kind': 'executable'}
          ],
        },
      });
      final errors = bad.validate();
      expect(errors.any((e) => e.contains('id')), isTrue);
      expect(errors.any((e) => e.contains('relative path')), isTrue);
    });

    test('normalises legacy v1 manifests (binaries + command template)', () {
      final legacy = PluginManifest.fromJson({
        'id': 'legacy-plugin',
        'name': 'Legacy',
        'version': '1.0.0',
        'author': 'Legacy Author',
        'minCoreVersion': '3.0.0',
        'binaries': {
          currentPlatformKey(): {'executable': 'tool', 'sha256': 'a' * 64}
        },
        'extensions': [
          {
            'ext': '.leg',
            'format': 'LEG',
            'platform': 'Legacy',
            'color': '#fff'
          }
        ],
        'conversions': [
          {
            'from': 'ISO',
            'to': 'LEG',
            'command': '{bin} convert "{in}" "{out}"'
          }
        ],
      });
      expect(legacy.schemaVersion, 1);
      expect(legacy.publisher.name, 'Legacy Author');
      expect(legacy.routes.single.key, 'ISO->LEG');
      // Template migrated into structured args.
      expect(legacy.execution.args.first.kind, PluginArgKind.executable);
      expect(legacy.execution.args.map((a) => a.kind),
          containsAll([PluginArgKind.input, PluginArgKind.output]));
      expect(legacy.validate(), isEmpty);
    });
  });

  group('PluginRegistry route precedence', () {
    test('plugin route cannot shadow a built-in route without override', () {
      final manifest = PluginManifest.fromJson(
        _v2Manifest(id: 'hijacker', from: 'ISO', to: 'CHD', override: false),
      );
      PluginRegistry.instance.registerPlugin(manifest);

      final coreRoutes = {'ISO->CHD'};
      expect(
        PluginRegistry.instance.resolveRoute('ISO', 'CHD', coreRoutes),
        isNull,
        reason: 'built-in ISO->CHD must win when override is false',
      );
    });

    test('plugin route with override takes precedence', () {
      final manifest = PluginManifest.fromJson(
        _v2Manifest(id: 'overrider', from: 'ISO', to: 'CHD', override: true),
      );
      PluginRegistry.instance.registerPlugin(manifest);

      final coreRoutes = {'ISO->CHD'};
      expect(
        PluginRegistry.instance.resolveRoute('ISO', 'CHD', coreRoutes),
        isNotNull,
      );
    });

    test('plugin route fills a gap the core does not handle', () {
      final manifest = PluginManifest.fromJson(
        _v2Manifest(id: 'gapper', from: 'ZZZ', to: 'ISO'),
      );
      PluginRegistry.instance.registerPlugin(manifest);
      expect(
        PluginRegistry.instance.resolveRoute('ZZZ', 'ISO', {'ISO->CHD'}),
        isNotNull,
      );
    });
  });

  group('PluginInstaller', () {
    test('installs a valid archive and registers it', () async {
      final manifest = _v2Manifest(binaryContent: 'hello-binary');
      final archive = _writeOrplug(tempDir, 'ok.orplug', {
        'plugin.json': utf8.encode(jsonEncode(manifest)),
        'bin/tool': utf8.encode('hello-binary'),
      });

      final result =
          await PluginManager.instance.installPluginDetailed(archive);
      expect(result.success, isTrue, reason: result.error);
      expect(
          PluginManager.instance.installedPlugins.single.id, 'xbox360-tools');
    });

    test('rejects installation when the archive checksum mismatches', () async {
      final manifest = _v2Manifest();
      final archive = _writeOrplug(tempDir, 'mismatch.orplug', {
        'plugin.json': utf8.encode(jsonEncode(manifest)),
        'bin/tool': utf8.encode('mock-binary-xbox360-tools'),
      });

      final result = await PluginManager.instance.installPluginDetailed(
        archive,
        expectedSha256: 'b' * 64,
      );
      expect(result.success, isFalse);
      expect(result.error, contains('checksum mismatch'));
    });

    test('rejects installation when core is older than minCoreVersion',
        () async {
      PluginManager.instance.setCoreVersionOverride(const SemVer(3, 0, 0));
      final manifest = _v2Manifest(minCore: '9.9.9');
      final archive = _writeOrplug(tempDir, 'future.orplug', {
        'plugin.json': utf8.encode(jsonEncode(manifest)),
        'bin/tool': utf8.encode('mock-binary-xbox360-tools'),
      });

      final result =
          await PluginManager.instance.installPluginDetailed(archive);
      expect(result.success, isFalse);
      expect(result.error, contains('requires OpenROM core'));
    });

    test('rejects a binary whose SHA-256 does not match the manifest',
        () async {
      final manifest = _v2Manifest(); // declares hash of "mock-binary-…"
      final archive = _writeOrplug(tempDir, 'corrupt.orplug', {
        'plugin.json': utf8.encode(jsonEncode(manifest)),
        'bin/tool': utf8.encode('TAMPERED CONTENT'),
      });

      final result =
          await PluginManager.instance.installPluginDetailed(archive);
      expect(result.success, isFalse);
      expect(result.error, contains('SHA-256 mismatch'));
    });

    test('blocks zip-slip path traversal', () async {
      final manifest = _v2Manifest();
      final archive = _writeOrplug(tempDir, 'slip.orplug', {
        'plugin.json': utf8.encode(jsonEncode(manifest)),
        'bin/tool': utf8.encode('mock-binary-xbox360-tools'),
        '../escape.txt': utf8.encode('pwned'),
      });

      final result =
          await PluginManager.instance.installPluginDetailed(archive);
      expect(result.success, isFalse);
      expect(result.error, contains('escapes the plugin directory'));
      expect(File(p.join(tempDir.path, 'escape.txt')).existsSync(), isFalse);
    });

    test('atomic install preserves the previous version on failure', () async {
      // Install v1 successfully.
      final v1 = _v2Manifest(version: '1.0.0', binaryContent: 'v1-binary');
      final archive1 = _writeOrplug(tempDir, 'v1.orplug', {
        'plugin.json': utf8.encode(jsonEncode(v1)),
        'bin/tool': utf8.encode('v1-binary'),
      });
      expect(
        (await PluginManager.instance.installPluginDetailed(archive1)).success,
        isTrue,
      );

      // Attempt a broken upgrade (bad binary hash) — must be refused.
      final v2 = _v2Manifest(version: '2.0.0');
      final archive2 = _writeOrplug(tempDir, 'v2.orplug', {
        'plugin.json': utf8.encode(jsonEncode(v2)),
        'bin/tool': utf8.encode('TAMPERED'),
      });
      final failed =
          await PluginManager.instance.installPluginDetailed(archive2);
      expect(failed.success, isFalse);

      // The v1 install must still be intact and loadable.
      await PluginManager.instance.loadInstalledPlugins();
      expect(PluginManager.instance.installedPlugins.single.version,
          const SemVer(1, 0, 0));
    });
  });

  group('PluginExecutor', () {
    test('runs a plugin with a structured argument vector', () async {
      if (Platform.isWindows) return; // uses a POSIX shell script

      const script = '#!/bin/sh\necho "in=\$1 out=\$2"\nexit 0\n';
      final manifest = _v2Manifest(
        id: 'runner',
        from: 'AAAA',
        to: 'BBBB',
        executable: 'tool.sh',
        binaryContent: script,
      );
      // Adjust args to a simple two-argument shape.
      (manifest['execution'] as Map<String, dynamic>)['args'] = [
        {'kind': 'input'},
        {'kind': 'output'},
      ];

      final archive = _writeOrplug(tempDir, 'runner.orplug', {
        'plugin.json': utf8.encode(jsonEncode(manifest)),
        'tool.sh': utf8.encode(script),
      });
      final install =
          await PluginManager.instance.installPluginDetailed(archive);
      expect(install.success, isTrue, reason: install.error);

      final conv = PluginRegistry.instance.getConversion('AAAA', 'BBBB');
      expect(conv, isNotNull);

      final input = File(p.join(tempDir.path, 'in.aaaa'))
        ..writeAsStringSync('data');
      final logs = <String>[];

      final result = await PluginManager.instance.executor.run(
        conversion: conv!,
        inputPath: input.path,
        outputPath: p.join(tempDir.path, 'out.bbbb'),
        outputDir: tempDir.path,
        onLog: logs.add,
      );

      expect(result.success, isTrue, reason: result.error);
      expect(logs.join('\n'), contains('in='));
    });

    test('does not shell-interpret paths with special characters', () async {
      if (Platform.isWindows) return;

      const script = '#!/bin/sh\nprintf "%s" "\$1"\nexit 0\n';
      final manifest = _v2Manifest(
        id: 'safepaths',
        from: 'CCCC',
        to: 'DDDD',
        executable: 'tool.sh',
        binaryContent: script,
      );
      (manifest['execution'] as Map<String, dynamic>)['args'] = [
        {'kind': 'input'},
      ];

      final archive = _writeOrplug(tempDir, 'safe.orplug', {
        'plugin.json': utf8.encode(jsonEncode(manifest)),
        'tool.sh': utf8.encode(script),
      });
      final install =
          await PluginManager.instance.installPluginDetailed(archive);
      expect(install.success, isTrue, reason: install.error);

      // A path that would be dangerous if passed through a shell.
      final evil = p.join(tempDir.path, 'a; rm -rf x; \$(whoami).cccc');
      File(evil).writeAsStringSync('data');

      final conv = PluginRegistry.instance.getConversion('CCCC', 'DDDD')!;
      final logs = <String>[];
      final result = await PluginManager.instance.executor.run(
        conversion: conv,
        inputPath: evil,
        outputPath: p.join(tempDir.path, 'o.dddd'),
        outputDir: tempDir.path,
        onLog: logs.add,
      );

      expect(result.success, isTrue, reason: result.error);
      // The literal path must arrive intact as a single argv element.
      expect(logs.join('\n'), contains('a; rm -rf x;'));
    });
  });
}
