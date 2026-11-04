// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import 'plugin_manifest.dart';
import 'plugin_version.dart';

/// Maps a `bin/<os>/<arch>/…` executable path to the manifest platform key
/// (`windows_x64`, `linux_x64`, `macos_arm64`, …). Returns `null` when the path
/// does not follow the convention.
String? platformKeyFromExecutable(String relPath) {
  final parts = p.split(relPath.replaceAll('\\', '/'));
  if (parts.length < 4) return null;
  if (parts[0] != 'bin') return null;

  final os = parts[1].toLowerCase();
  final arch = parts[2].toLowerCase();

  final String osKey;
  switch (os) {
    case 'windows':
    case 'win':
      osKey = 'windows';
      break;
    case 'linux':
      osKey = 'linux';
      break;
    case 'macos':
    case 'darwin':
    case 'osx':
      osKey = 'macos';
      break;
    default:
      return null;
  }

  final String archKey;
  switch (arch) {
    case 'x86_64':
    case 'x64':
    case 'amd64':
      archKey = 'x64';
      break;
    case 'arm64':
    case 'aarch64':
      archKey = 'arm64';
      break;
    default:
      return null;
  }

  return '${osKey}_$archKey';
}

/// Outcome of a scaffold / pack operation.
class PluginBuildResult {
  final bool success;
  final String? error;
  final List<String> warnings;
  final String? outputPath;
  final String? archiveSha256;
  final int archiveSize;
  final PluginManifest? manifest;
  final Map<String, dynamic>? marketplaceEntry;

  const PluginBuildResult({
    required this.success,
    this.error,
    this.warnings = const [],
    this.outputPath,
    this.archiveSha256,
    this.archiveSize = 0,
    this.manifest,
    this.marketplaceEntry,
  });

  const PluginBuildResult.failure(String this.error)
      : success = false,
        warnings = const [],
        outputPath = null,
        archiveSha256 = null,
        archiveSize = 0,
        manifest = null,
        marketplaceEntry = null;
}

/// Outcome of a validate operation.
class PluginValidationResult {
  final bool success;
  final List<String> errors;
  final List<String> warnings;
  final PluginManifest? manifest;

  const PluginValidationResult({
    required this.success,
    this.errors = const [],
    this.warnings = const [],
    this.manifest,
  });

  Map<String, dynamic> toJson() => {
        'valid': success,
        'errors': errors,
        'warnings': warnings,
        if (manifest != null) 'manifest': manifest!.toJson(),
      };
}

/// `orplug-builder` — the official plugin developer toolchain.
///
/// Mirrors the `.orplug` (ZIP) contract enforced by [PluginInstaller]:
///  * a folder scaffold ([init]),
///  * a strict validator ([validate]) that also checks SHA-256 integrity and
///    Zip-Slip safety, and
///  * a packer ([pack]) that hashes binaries, validates the manifest and
///    produces a marketplace entry.
class OrplugBuilder {
  final void Function(String message) log;

  /// Core version used for the generated `minCoreVersion` default.
  final SemVer coreVersion;

  OrplugBuilder({
    void Function(String message)? log,
    SemVer? coreVersion,
  })  : log = log ?? _noop,
        coreVersion = coreVersion ?? const SemVer(3, 9, 0);

  static void _noop(String _) {}

  /// Scaffolds a complete starter plugin folder under [targetDir].
  ///
  /// Creates `plugin.json`, `README.md`, `LICENSE`, `icon.png` placeholder and
  /// the `bin/<os>/<arch>/` tree. Returns a failure when the folder already
  /// contains a `plugin.json` (to avoid clobbering an existing plugin).
  PluginBuildResult init(
    String targetDir, {
    String? name,
    String? id,
  }) {
    final dir = Directory(targetDir);
    final manifestPath = p.join(dir.path, 'plugin.json');
    if (File(manifestPath).existsSync()) {
      return const PluginBuildResult.failure(
        'A "plugin.json" already exists in the target directory.',
      );
    }

    final slug = _slugify(id ?? name ?? p.basename(p.absolute(targetDir)));
    final displayName = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : _titleCase(slug);

    if (!kPluginIdPattern.hasMatch(slug)) {
      return PluginBuildResult.failure(
        'Invalid plugin id "$slug": must match ${kPluginIdPattern.pattern}.',
      );
    }

    final manifest = <String, dynamic>{
      'schemaVersion': kPluginSchemaVersion,
      'id': slug,
      'name': displayName,
      'version': '1.0.0',
      'minCoreVersion': '${coreVersion.major}.${coreVersion.minor}.0',
      'publisher': {'id': 'your-publisher-id', 'name': 'Your Publisher Name'},
      'category': 'Utility',
      'description': 'Short description of the plugin.',
      'routes': <dynamic>[
        {'from': 'ISO', 'to': 'MYFMT'},
      ],
      'execution': {
        'kind': 'process',
        'environments': {
          'windows_x64': {
            'executable': 'bin/windows/x86_64/$slug.exe',
            'sha256': '',
          },
          'linux_x64': {
            'executable': 'bin/linux/x86_64/$slug',
            'sha256': '',
          },
          'macos_arm64': {
            'executable': 'bin/macos/arm64/$slug',
            'sha256': '',
          },
        },
        'args': [
          {'kind': 'executable'},
          {'kind': 'literal', 'value': 'convert'},
          {'kind': 'input'},
          {'kind': 'literal', 'value': '--output'},
          {'kind': 'output'},
        ],
      },
      'extensions': <dynamic>[
        {
          'ext': '.myfmt',
          'format': 'MYFMT',
          'platform': 'Custom',
          'color': '#7a8a9a',
        },
      ],
    };

    try {
      dir.createSync(recursive: true);
      File(manifestPath).writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
      );

      File(p.join(dir.path, 'README.md'))
          .writeAsStringSync(_readme(displayName));
      File(p.join(dir.path, 'LICENSE'))
          .writeAsStringSync(_license(displayName));
      _writePlaceholderIcon(File(p.join(dir.path, 'icon.png')));

      for (final binDir in const [
        'bin/windows/x86_64',
        'bin/linux/x86_64',
        'bin/macos/arm64',
      ]) {
        Directory(p.join(dir.path, binDir)).createSync(recursive: true);
      }
    } catch (e) {
      return PluginBuildResult.failure('Failed to scaffold plugin: $e');
    }

    log('[ORPLUG] Scaffolded plugin "$slug" in ${dir.path}');
    return PluginBuildResult(
      success: true,
      outputPath: dir.path,
      manifest: PluginManifest.fromJson(manifest),
      warnings: const [
        'Add your native binaries under bin/<os>/<arch>/ then run '
            '`--plugin-pack` to compute their SHA-256 hashes.',
      ],
    );
  }

  /// Validates a plugin folder or a `.orplug` archive at [path].
  PluginValidationResult validate(String path) {
    final entityType = FileSystemEntity.typeSync(path);
    if (entityType == FileSystemEntityType.notFound) {
      return PluginValidationResult(
        success: false,
        errors: ['Path not found: $path'],
      );
    }
    if (entityType == FileSystemEntityType.directory) {
      return _validateDirectory(Directory(path));
    }
    return _validateArchive(File(path));
  }

  PluginValidationResult _validateDirectory(Directory dir) {
    final errors = <String>[];
    final warnings = <String>[];

    final manifestFile = File(p.join(dir.path, 'plugin.json'));
    if (!manifestFile.existsSync()) {
      return const PluginValidationResult(
        success: false,
        errors: ['Missing "plugin.json" in the plugin directory.'],
      );
    }

    final PluginManifest manifest;
    final Map<String, dynamic> raw;
    try {
      raw = jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      manifest = PluginManifest.fromJson(raw);
    } catch (e) {
      return PluginValidationResult(
        success: false,
        errors: ['Malformed "plugin.json": $e'],
      );
    }

    // A source folder is validated *before* packing, so a missing binary or a
    // not-yet-computed SHA-256 is a warning, not a hard error. A present binary
    // whose digest does not match is always an error.
    for (final e in manifest.validate()) {
      if (e.contains('missing a "sha256"')) {
        warnings.add(e);
      } else {
        errors.add(e);
      }
    }
    _checkSemVer(raw['version'], raw['minCoreVersion'], errors);

    // Zip-Slip / containment for every declared executable.
    final root = p.normalize(p.absolute(dir.path));
    manifest.execution.environments.forEach((key, env) {
      if (env.executable.trim().isEmpty) return;
      final resolved = p.normalize(p.absolute(p.join(root, env.executable)));
      if (resolved != root && !resolved.startsWith(root + p.separator)) {
        errors.add('Executable "${env.executable}" escapes the plugin folder.');
        return;
      }
      final bin = File(resolved);
      if (!bin.existsSync()) {
        warnings.add(
          'No binary found for "$key" ("${env.executable}"); build it before '
          'packing.',
        );
        return;
      }
      if (env.sha256.trim().isEmpty) {
        warnings.add(
          'Missing "sha256" for "$key"; run `--plugin-pack` to generate it.',
        );
      } else {
        final actual = _sha256File(bin);
        if (actual.toLowerCase() != env.sha256.trim().toLowerCase()) {
          errors.add(
            'SHA-256 mismatch for "$key" ("${env.executable}"): expected '
            '${env.sha256.trim()}, got $actual.',
          );
        }
      }
    });

    return PluginValidationResult(
      success: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      manifest: manifest,
    );
  }

  PluginValidationResult _validateArchive(File archive) {
    final errors = <String>[];
    final warnings = <String>[];

    final Archive decoded;
    try {
      decoded = ZipDecoder().decodeBytes(archive.readAsBytesSync());
    } catch (e) {
      return PluginValidationResult(
        success: false,
        errors: ['Not a valid .orplug (ZIP) archive: $e'],
      );
    }

    final entries = <String, ArchiveFile>{};
    for (final entry in decoded) {
      if (entry.isSymbolicLink) {
        errors.add('Archive contains a symbolic link ("${entry.name}").');
        continue;
      }
      final name = entry.name;
      if (name.contains('\u0000')) {
        errors.add('Archive contains an entry with an illegal null byte.');
        continue;
      }
      final normalized = p.normalize(name.replaceAll('\\', '/'));
      if (p.isAbsolute(normalized) ||
          normalized == '..' ||
          normalized.startsWith('../')) {
        errors.add('Zip-Slip: entry escapes the plugin directory ("$name").');
        continue;
      }
      if (entry.isFile) entries[normalized] = entry;
    }

    final manifestEntry = entries['plugin.json'];
    if (manifestEntry == null) {
      errors.add('Archive does not contain a "plugin.json" manifest.');
      return PluginValidationResult(success: false, errors: errors);
    }

    final PluginManifest manifest;
    final Map<String, dynamic> manifestJson;
    try {
      manifestJson = jsonDecode(utf8.decode(manifestEntry.content as List<int>))
          as Map<String, dynamic>;
      manifest = PluginManifest.fromJson(manifestJson);
    } catch (e) {
      errors.add('Malformed "plugin.json": $e');
      return PluginValidationResult(success: false, errors: errors);
    }

    for (final e in manifest.validate()) {
      if (e.contains('missing a "sha256"')) {
        warnings.add(e);
      } else {
        errors.add(e);
      }
    }
    _checkSemVer(
      manifestJson['version'],
      manifestJson['minCoreVersion'],
      errors,
    );

    manifest.execution.environments.forEach((key, env) {
      if (env.executable.trim().isEmpty) return;
      final normalized = p.normalize(env.executable.replaceAll('\\', '/'));
      final entry = entries[normalized];
      if (entry == null) {
        warnings.add(
          'Archive has no binary for "$key" ("${env.executable}").',
        );
        return;
      }
      if (env.sha256.trim().isEmpty) {
        warnings.add('Missing "sha256" for "$key".');
        return;
      }
      final actual = sha256.convert(entry.content as List<int>).toString();
      if (actual.toLowerCase() != env.sha256.trim().toLowerCase()) {
        errors.add(
          'SHA-256 mismatch for "$key" ("${env.executable}"): expected '
          '${env.sha256.trim()}, got $actual.',
        );
      }
    });

    return PluginValidationResult(
      success: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      manifest: manifest,
    );
  }

  /// Hashes every `bin/<os>/<arch>/…` executable, injects the digests into
  /// `plugin.json`, validates the manifest, then packages the folder into
  /// `<id>-<version>.orplug`.
  PluginBuildResult pack(String sourceDir, {String? outputPath}) {
    final dir = Directory(sourceDir);
    if (!dir.existsSync()) {
      return PluginBuildResult.failure('Plugin folder not found: $sourceDir');
    }

    final manifestFile = File(p.join(dir.path, 'plugin.json'));
    if (!manifestFile.existsSync()) {
      return const PluginBuildResult.failure(
        'Missing "plugin.json" in the plugin folder.',
      );
    }

    final Map<String, dynamic> raw;
    try {
      raw = jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    } catch (e) {
      return PluginBuildResult.failure('Malformed "plugin.json": $e');
    }

    final warnings = <String>[];
    final execution = raw['execution'];
    if (execution is! Map<String, dynamic>) {
      return const PluginBuildResult.failure(
        'Manifest has no "execution" block to inject binaries into.',
      );
    }

    final environments = (execution['environments'] as Map<String, dynamic>?) ??
        <String, dynamic>{};
    execution['environments'] = environments;

    // 1. Scan bin/<os>/<arch>/ and hash each executable.
    final binDir = Directory(p.join(dir.path, 'bin'));
    if (!binDir.existsSync()) {
      warnings.add('No "bin/" directory found; no executables were hashed.');
    } else {
      final files = binDir
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

      for (final file in files) {
        final rel = p.relative(file.path, from: dir.path);
        final relPosix = p.split(rel).join('/');
        final platformKey = platformKeyFromExecutable(relPosix);
        if (platformKey == null) {
          warnings.add(
            'Skipped "$relPosix": expected bin/<os>/<arch>/<tool> layout.',
          );
          continue;
        }
        final digest = _sha256File(file);
        environments[platformKey] = {
          'executable': relPosix,
          'sha256': digest,
        };
        log('[ORPLUG] $platformKey -> $relPosix ($digest)');
      }
    }

    // Drop scaffold placeholders that were never built (declared with an empty
    // hash and no file on disk); they would fail validation otherwise.
    for (final key in environments.keys.toList()) {
      final entry = environments[key];
      if (entry is! Map) {
        environments.remove(key);
        continue;
      }
      final rel = entry['executable']?.toString() ?? '';
      final declaredHash = entry['sha256']?.toString() ?? '';
      if (declaredHash.trim().isNotEmpty || rel.trim().isEmpty) continue;
      final resolved = p.normalize(p.absolute(p.join(dir.path, rel)));
      if (!File(resolved).existsSync()) {
        environments.remove(key);
        warnings.add('Skipped "$key": no binary built at "$rel".');
      }
    }

    // 2. Persist the injected manifest.
    try {
      manifestFile.writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(raw)}\n',
      );
    } catch (e) {
      return PluginBuildResult.failure('Could not write "plugin.json": $e');
    }

    // 3. Validate the manifest against the shared rules.
    final PluginManifest manifest;
    try {
      manifest = PluginManifest.fromJson(raw);
    } catch (e) {
      return PluginBuildResult.failure('Manifest parse failed: $e');
    }
    final errors = <String>[...manifest.validate()];
    _checkSemVer(raw['version'], raw['minCoreVersion'], errors);
    if (errors.isNotEmpty) {
      return PluginBuildResult(
        success: false,
        error: 'Manifest validation failed: ${errors.join('; ')}',
        warnings: warnings,
        manifest: manifest,
      );
    }

    // 4. Package the folder into a .orplug ZIP.
    final defaultName = '${manifest.id}-${manifest.version}.orplug';
    final out =
        outputPath ?? p.join(p.dirname(p.absolute(dir.path)), defaultName);
    final outFile = File(out);
    try {
      outFile.parent.createSync(recursive: true);
      _zipDirectory(dir, outFile);
    } catch (e) {
      return PluginBuildResult.failure('Packaging failed: $e');
    }

    final archiveBytes = outFile.readAsBytesSync();
    final archiveSha = sha256.convert(archiveBytes).toString();

    final entry = _marketplaceEntry(manifest, archiveSha, archiveBytes.length);

    log('[ORPLUG] Packed ${manifest.id} v${manifest.version} -> $out');
    return PluginBuildResult(
      success: true,
      warnings: warnings,
      outputPath: out,
      archiveSha256: archiveSha,
      archiveSize: archiveBytes.length,
      manifest: manifest,
      marketplaceEntry: entry,
    );
  }

  /// Builds the marketplace snippet (matching `store_manifest.json`).
  Map<String, dynamic> _marketplaceEntry(
    PluginManifest manifest,
    String sha256Hex,
    int size,
  ) {
    final artifacts = <String, dynamic>{};
    manifest.execution.environments.forEach((key, env) {
      artifacts[key] = {
        'url': 'https://plugins.openrom.dev/artifacts/'
            '${manifest.id}-${manifest.version}.orplug',
        'sha256': sha256Hex,
        'size': size,
      };
    });

    return {
      'id': manifest.id,
      'name': manifest.name,
      'description': manifest.description,
      'publisherId': manifest.publisher.id,
      'tags': <String>[],
      'channels': {
        'stable': {
          'version': manifest.version.toString(),
          'minCoreVersion': manifest.minCoreVersion?.toString() ?? '',
          'artifacts': artifacts,
        },
      },
    };
  }

  static void _checkSemVer(
    Object? version,
    Object? minCoreVersion,
    List<String> errors,
  ) {
    if (SemVer.tryParse(version?.toString() ?? '') == null) {
      errors.add(
        'Plugin "version" must be a valid SemVer (e.g. "1.2.0"), got '
        '"$version".',
      );
    }
    if (SemVer.tryParseLoose(minCoreVersion?.toString()) == null) {
      errors.add(
        'Plugin "minCoreVersion" must be a valid SemVer (e.g. "3.9.0").',
      );
    }
  }

  static String _sha256File(File file) =>
      sha256.convert(file.readAsBytesSync()).toString().toLowerCase();

  /// Zips [source] into [outFile] deterministically, skipping hidden files and
  /// the output archive itself.
  static void _zipDirectory(Directory source, File outFile) {
    final outPath = p.normalize(p.absolute(outFile.path));
    final encoder = ZipFileEncoder();
    encoder.create(outPath);

    final files = source
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    for (final file in files) {
      final abs = p.normalize(p.absolute(file.path));
      if (abs == outPath) continue;
      if (p.basename(file.path).startsWith('.')) continue;
      final rel = p.split(p.relative(file.path, from: source.path)).join('/');
      encoder.addFile(file, rel);
    }
    encoder.closeSync();
  }

  static String _slugify(String value) {
    final lowered =
        value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_-]+'), '-');
    return lowered.replaceAll(RegExp(r'^-+|-+$'), '');
  }

  static String _titleCase(String slug) => slug
      .split(RegExp(r'[-_]'))
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  static String _readme(String name) => '''
# $name

A plugin for OpenROM.

## Building

1. Place your native binaries under `bin/<os>/<arch>/`.
2. Run `openrom-core --plugin-pack .` to hash the binaries and build the
   `.orplug` archive.
3. Run `openrom-core --plugin-validate .` to check the manifest.
''';

  static String _license(String name) => '''
$name — OpenROM plugin
Copyright (C) ${DateTime.now().year}

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program. If not, see <https://www.gnu.org/licenses/>.
''';

  /// A minimal valid 1x1 PNG so `icon.png` is always present.
  static void _writePlaceholderIcon(File file) {
    const png = <int>[
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // signature
      0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR length + type
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1
      0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, // bit depth etc.
      0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, // IDAT length + type
      0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
      0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
      0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, // IEND
      0x42, 0x60, 0x82,
    ];
    file.writeAsBytesSync(png);
  }
}
