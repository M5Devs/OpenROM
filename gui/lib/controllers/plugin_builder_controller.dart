// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:openrom_core/openrom_core.dart';
import 'package:path/path.dart' as p;

/// The platform keys the studio can build for, in display order.
const List<String> kStudioPlatformKeys = [
  'windows_x64',
  'windows_arm64',
  'linux_x64',
  'linux_arm64',
  'macos_x64',
  'macos_arm64',
];

/// Maps a manifest platform key to its `bin/<os>/<arch>` directory.
String? studioBinDir(String platformKey) {
  const map = {
    'windows_x64': 'bin/windows/x86_64',
    'windows_arm64': 'bin/windows/arm64',
    'linux_x64': 'bin/linux/x86_64',
    'linux_arm64': 'bin/linux/arm64',
    'macos_x64': 'bin/macos/x86_64',
    'macos_arm64': 'bin/macos/arm64',
  };
  return map[platformKey];
}

/// A binary currently present under `bin/` for one platform.
class StudioBinary {
  final String platformKey;
  final String path;
  final int size;

  const StudioBinary({
    required this.platformKey,
    required this.path,
    required this.size,
  });

  String get fileName => p.basename(path);

  String get sizeLabel {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Form state + build actions for the Visual `.orplug` Builder Studio.
///
/// The studio is a thin form over the core [OrplugBuilder]: it keeps the
/// user-editable manifest fields, persists them to `<projectDir>/plugin.json`
/// (so the CLI and the GUI share one source of truth) and runs
/// init / validate / pack on demand. Binaries live on disk under `bin/`; the
/// studio only mirrors them, so a project built here is byte-identical to one
/// built with `openrom-core --plugin-pack`.
class PluginBuilderController extends ChangeNotifier {
  final OrplugBuilder _builder;

  PluginBuilderController({OrplugBuilder? builder, SemVer? coreVersion})
      : _builder = builder ?? OrplugBuilder(coreVersion: coreVersion);

  // ── Form fields ────────────────────────────────────────────────────────────
  String _id = '';
  String _name = '';
  String _version = '1.0.0';
  String _minCoreVersion = '3.9.0';
  String _publisherId = 'your-publisher-id';
  String _publisherName = 'Your Publisher Name';
  bool _publisherVerified = false;
  String _category = 'Utility';
  String _description = '';
  final List<String> _routes = [];
  String _argsTemplate = 'convert --input {in} --output {out}';

  String _projectDir = '';
  bool _projectLoaded = false;
  List<StudioBinary> _binaries = const [];

  bool _isBusy = false;
  String? _statusMessage;
  String? _errorMessage;

  PluginValidationResult? _validation;
  PluginBuildResult? _packResult;
  String? _packOutputPath;

  // ── Getters ────────────────────────────────────────────────────────────────
  String get id => _id;
  String get name => _name;
  String get version => _version;
  String get minCoreVersion => _minCoreVersion;
  String get publisherId => _publisherId;
  String get publisherName => _publisherName;
  bool get publisherVerified => _publisherVerified;
  String get category => _category;
  String get description => _description;
  List<String> get routes => List.unmodifiable(_routes);
  String get argsTemplate => _argsTemplate;

  String get projectDir => _projectDir;
  bool get projectLoaded => _projectLoaded;
  List<StudioBinary> get binaries => List.unmodifiable(_binaries);

  bool get isBusy => _isBusy;
  String? get statusMessage => _statusMessage;
  String? get errorMessage => _errorMessage;

  PluginValidationResult? get validation => _validation;
  PluginBuildResult? get packResult => _packResult;
  String? get packOutputPath => _packOutputPath;

  /// Whether the current form is well-formed enough to build.
  bool get canBuild =>
      _projectLoaded && _id.isNotEmpty && _name.isNotEmpty && !_isBusy;

  /// Human-readable label for a platform key (`linux_x64` → `Linux x64`).
  static String platformLabel(String key) {
    final parts = key.split('_');
    if (parts.length != 2) return key;
    final os = switch (parts[0]) {
      'windows' => 'Windows',
      'linux' => 'Linux',
      'macos' => 'macOS',
      _ => parts[0],
    };
    final arch = switch (parts[1]) {
      'x64' => 'x64',
      'arm64' => 'ARM64',
      _ => parts[1],
    };
    return '$os $arch';
  }

  void clearMessages() {
    _statusMessage = null;
    _errorMessage = null;
    notifyListeners();
  }

  // ── Field setters (each notifies so the preview stays live) ────────────────
  void setIdentity({String? id, String? name}) {
    if (id != null) _id = _sanitizeId(id);
    if (name != null) _name = name;
    notifyListeners();
  }

  void setVersion(String value) {
    _version = value;
    notifyListeners();
  }

  void setMinCoreVersion(String value) {
    _minCoreVersion = value;
    notifyListeners();
  }

  void setPublisher({String? id, String? name, bool? verified}) {
    if (id != null) _publisherId = id;
    if (name != null) _publisherName = name;
    if (verified != null) _publisherVerified = verified;
    notifyListeners();
  }

  void setCategory(String value) {
    _category = value;
    notifyListeners();
  }

  void setDescription(String value) {
    _description = value;
    notifyListeners();
  }

  void setArgsTemplate(String value) {
    _argsTemplate = value;
    notifyListeners();
  }

  void addRoute(String route) {
    final trimmed = route.trim().toUpperCase().replaceAll('->', '->');
    if (trimmed.isEmpty || !trimmed.contains('->')) return;
    if (_routes.contains(trimmed)) return;
    _routes.add(trimmed);
    notifyListeners();
  }

  void removeRoute(String route) {
    _routes.remove(route);
    notifyListeners();
  }

  // ── Project lifecycle ──────────────────────────────────────────────────────

  /// Picks an existing project folder and loads it.
  Future<void> pickProjectDir() async {
    try {
      final selected = await FilePicker.getDirectoryPath(
        dialogTitle: 'Select a plugin project folder',
      );
      if (selected == null || selected.isEmpty) return;
      await openProject(selected);
    } catch (e) {
      _errorMessage = 'Failed to open folder: $e';
      notifyListeners();
    }
  }

  /// Opens [dir] as a project. When it has no `plugin.json` the form keeps the
  /// current values so the user can scaffold into it.
  Future<void> openProject(String dir) async {
    _projectDir = dir;
    _projectLoaded = true;
    _packResult = null;
    _packOutputPath = null;
    _validation = null;
    _errorMessage = null;

    final manifestFile = File(p.join(dir, 'plugin.json'));
    if (manifestFile.existsSync()) {
      try {
        final raw = jsonDecode(manifestFile.readAsStringSync());
        if (raw is Map<String, dynamic>) {
          _applyManifest(PluginManifest.fromJson(raw));
        }
        _statusMessage = 'Loaded project from ${p.basename(dir)}';
      } catch (e) {
        _errorMessage = 'Malformed plugin.json: $e';
      }
    } else {
      if (_name.isEmpty) _name = _titleCase(_sanitizeId(p.basename(dir)));
      if (_id.isEmpty) _id = _sanitizeId(p.basename(dir));
      _statusMessage = 'New project: ${p.basename(dir)}';
    }

    await _scanBinaries();
    notifyListeners();
  }

  /// Scaffolds a starter project in [dir] via the core [OrplugBuilder].
  Future<bool> scaffold(String dir, {bool overwrite = false}) async {
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final manifestPath = p.join(dir, 'plugin.json');
      if (overwrite && File(manifestPath).existsSync()) {
        File(manifestPath).deleteSync();
      }
      final res = _builder.init(
        dir,
        name: _name.isEmpty ? null : _name,
        id: _id.isEmpty ? null : _id,
        category: _category,
      );
      if (!res.success) {
        _errorMessage = res.error;
        return false;
      }
      _projectDir = dir;
      _projectLoaded = true;
      _statusMessage = 'Scaffolded plugin "${res.manifest?.id}".';
      await openProject(dir);
      return true;
    } catch (e) {
      _errorMessage = 'Scaffold failed: $e';
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  /// Re-reads the manifest and rescans `bin/`.
  Future<void> refresh() async {
    if (!_projectLoaded) return;
    await openProject(_projectDir);
  }

  // ── Binaries ───────────────────────────────────────────────────────────────

  /// Picks a binary for [platformKey] and copies it into `bin/<os>/<arch>/`.
  Future<void> addBinary(String platformKey) async {
    if (!_projectLoaded) {
      _errorMessage = 'Open or scaffold a project first.';
      notifyListeners();
      return;
    }
    final binDir = studioBinDir(platformKey);
    if (binDir == null) return;

    try {
      final picked = await FilePicker.pickFile(
        dialogTitle: 'Select the ${platformLabel(platformKey)} binary',
      );
      final source = picked?.path;
      if (source == null || source.isEmpty) return;

      final targetDir = Directory(p.join(_projectDir, binDir))
        ..createSync(recursive: true);
      var fileName = p.basename(source);
      // Windows binaries must keep their .exe suffix to stay runnable.
      if (platformKey.startsWith('windows') && !fileName.endsWith('.exe')) {
        fileName = '$fileName.exe';
      }
      final target = File(p.join(targetDir.path, fileName));
      File(source).copySync(target.path);
      _statusMessage = 'Added ${p.basename(target.path)}.';
      _errorMessage = null;
      await _scanBinaries();
    } catch (e) {
      _errorMessage = 'Failed to add binary: $e';
    } finally {
      notifyListeners();
    }
  }

  /// Removes the binary for [platformKey] from `bin/`.
  Future<void> removeBinary(String platformKey) async {
    final binDir = studioBinDir(platformKey);
    if (binDir == null) return;
    final dir = Directory(p.join(_projectDir, binDir));
    if (dir.existsSync()) {
      try {
        dir.deleteSync(recursive: true);
      } catch (e) {
        _errorMessage = 'Failed to remove binary: $e';
        notifyListeners();
        return;
      }
    }
    await _scanBinaries();
    notifyListeners();
  }

  Future<void> _scanBinaries() async {
    final found = <StudioBinary>[];
    _sha256Cache.clear();
    final binRoot = Directory(p.join(_projectDir, 'bin'));
    if (!binRoot.existsSync()) {
      _binaries = found;
      return;
    }

    for (final entity in binRoot.listSync(recursive: true)) {
      if (entity is! File) continue;
      final rel = p.relative(entity.path, from: _projectDir);
      final key = platformKeyFromExecutable(rel);
      if (key == null) continue;
      found.add(StudioBinary(
        platformKey: key,
        path: entity.path,
        size: entity.lengthSync(),
      ));
      _sha256Cache[entity.path] = await sha256OfFile(entity.path);
    }
    found.sort((a, b) =>
        kStudioPlatformKeys.indexOf(a.platformKey) -
        kStudioPlatformKeys.indexOf(b.platformKey));
    _binaries = found;
  }

  /// SHA-256 of each discovered binary, computed once per scan.
  final Map<String, String> _sha256Cache = {};

  // ── Manifest persistence ───────────────────────────────────────────────────

  /// Writes the current form into `<projectDir>/plugin.json`, injecting the
  /// SHA-256 of every discovered binary.
  ///
  /// Returns `true` when the manifest was written and validated cleanly.
  Future<bool> saveManifest() async {
    if (!_projectLoaded) {
      _errorMessage = 'Open or scaffold a project first.';
      notifyListeners();
      return false;
    }

    _isBusy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final manifest = _buildManifestJson();
      final manifestFile = File(p.join(_projectDir, 'plugin.json'));
      manifestFile.writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
      );
      _validation = _builder.validate(_projectDir);
      if (!_validation!.success) {
        _errorMessage = 'Validation failed. See the issues below.';
        return false;
      }
      _statusMessage = 'Manifest saved.';
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save manifest: $e';
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  /// Validates the project without writing.
  Future<void> validate() async {
    if (!_projectLoaded) {
      _errorMessage = 'Open or scaffold a project first.';
      notifyListeners();
      return;
    }
    _isBusy = true;
    notifyListeners();
    try {
      _validation = _builder.validate(_projectDir);
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  /// Saves then packs the project into a `.orplug` archive.
  Future<bool> pack({String? outputPath}) async {
    if (!await saveManifest()) return false;

    _isBusy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = _builder.pack(_projectDir, outputPath: outputPath);
      _packResult = res;
      if (!res.success) {
        _errorMessage = res.error;
        return false;
      }
      _packOutputPath = res.outputPath;
      _statusMessage = 'Built ${p.basename(res.outputPath ?? '')}';
      _validation = _builder.validate(res.outputPath!);
      return true;
    } catch (e) {
      _errorMessage = 'Pack failed: $e';
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  /// The marketplace JSON snippet for the last successful pack, pretty-printed.
  String? get marketplaceJson {
    final entry = _packResult?.marketplaceEntry;
    if (entry == null) return null;
    return const JsonEncoder.withIndent('  ').convert(entry);
  }

  Map<String, dynamic> _buildManifestJson() {
    final environments = <String, dynamic>{};
    for (final bin in _binaries) {
      final rel = p.relative(bin.path, from: _projectDir).replaceAll('\\', '/');
      environments[bin.platformKey] = {
        'executable': rel,
        'sha256': _sha256Cache[bin.path] ?? '',
      };
    }

    return {
      'schemaVersion': kPluginSchemaVersion,
      'id': _id,
      'name': _name,
      'version': _version,
      'minCoreVersion': _minCoreVersion,
      'publisher': {
        'id': _publisherId,
        'name': _publisherName,
        'verified': _publisherVerified,
      },
      'category': _category,
      'description': _description,
      'routes': _routes
          .map((r) => r.split('->'))
          .where((parts) => parts.length == 2)
          .map((parts) => {'from': parts[0].trim(), 'to': parts[1].trim()})
          .toList(),
      'execution': {
        'kind': 'process',
        'environments': environments,
        'args': _parseArgs(_argsTemplate),
      },
    };
  }

  /// Parses a human-friendly arg template (`convert --input {in}`) into the
  /// structured [PluginArg] form used by Manifest v2.
  static List<Map<String, dynamic>> _parseArgs(String template) {
    const tokens = {
      '{bin}': 'executable',
      '{in}': 'input',
      '{out}': 'output',
      '{outdir}': 'outputDir',
      '{cue}': 'cue',
    };
    final args = <Map<String, dynamic>>[];
    for (final raw in template.split(RegExp(r'\s+'))) {
      final token = raw.trim();
      if (token.isEmpty) continue;
      final kind = tokens[token];
      args.add(
          kind != null ? {'kind': kind} : {'kind': 'literal', 'value': token});
    }
    if (args.isEmpty) args.add({'kind': 'executable'});
    return args;
  }

  void _applyManifest(PluginManifest manifest) {
    _id = manifest.id;
    _name = manifest.name;
    _version = manifest.version.toString();
    _minCoreVersion = manifest.minCoreVersion?.toString() ?? _minCoreVersion;
    _publisherId = manifest.publisher.id;
    _publisherName = manifest.publisher.name;
    _publisherVerified = manifest.publisher.verified;
    if (manifest.category.isNotEmpty) _category = manifest.category;
    _description = manifest.description;
    _routes
      ..clear()
      ..addAll(manifest.routes.map((r) => r.key));
    _argsTemplate = _formatArgs(manifest.execution.args);
  }

  /// Renders a structured arg vector back into the editable template form.
  static String _formatArgs(List<PluginArg> args) {
    if (args.isEmpty) return '';
    const reverse = {
      PluginArgKind.executable: '{bin}',
      PluginArgKind.input: '{in}',
      PluginArgKind.output: '{out}',
      PluginArgKind.outputDir: '{outdir}',
      PluginArgKind.cue: '{cue}',
    };
    return args
        .map((a) =>
            a.kind == PluginArgKind.literal ? a.value : (reverse[a.kind] ?? ''))
        .where((s) => s.isNotEmpty)
        .join(' ');
  }

  static String _sanitizeId(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_-]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');

  static String _titleCase(String slug) => slug
      .split(RegExp(r'[-_]+'))
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

/// Lowercase hex SHA-256 of a file, streamed so multi-hundred-MB binaries do
/// not land in memory.
Future<String> sha256OfFile(String path) async {
  final digest = await sha256.bind(File(path).openRead()).first;
  return digest.toString();
}
