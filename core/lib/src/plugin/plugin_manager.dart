// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../logger.dart' as logger;
import '../version_reader.dart';
import 'plugin_executor.dart';
import 'plugin_installer.dart';
import 'plugin_manifest.dart';
import 'plugin_registry.dart';
import 'plugin_version.dart';

/// High-level facade over discovery, installation, execution and the store.
///
/// This is the single entry point the GUI bridge talks to. It composes the
/// focused collaborators ([PluginInstaller], [PluginExecutor]) and owns the
/// in-memory [PluginRegistry].
class PluginManager {
  static final PluginManager instance = PluginManager._internal();

  PluginManager._internal();

  String? _customPluginsDir;
  SemVer? _coreVersionOverride;

  /// Overrides the plugins directory (used by tests and the GUI settings).
  void setCustomPluginsDir(String? dirPath) {
    _customPluginsDir = dirPath;
  }

  /// Overrides the detected core version (used by tests and by the GUI, which
  /// already knows the app version).
  void setCoreVersionOverride(SemVer? version) {
    _coreVersionOverride = version;
  }

  /// Resolves the user storage directory for plugins:
  /// - Windows: `%APPDATA%\OpenROM\plugins\`
  /// - Linux/macOS: `~/.local/share/openrom/plugins/` (fallback `~/.openrom/plugins/`)
  String get pluginsDir {
    if (_customPluginsDir != null && _customPluginsDir!.isNotEmpty) {
      return _customPluginsDir!;
    }

    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'];
      if (appData != null && appData.isNotEmpty) {
        return p.join(appData, 'OpenROM', 'plugins');
      }
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null && userProfile.isNotEmpty) {
        return p.join(userProfile, 'AppData', 'Roaming', 'OpenROM', 'plugins');
      }
    } else {
      final home = Platform.environment['HOME'] ??
          Platform.environment['USERPROFILE'] ??
          '';
      if (home.isNotEmpty) {
        final localShare =
            p.join(home, '.local', 'share', 'openrom', 'plugins');
        final localShareParent = p.join(home, '.local', 'share');
        if (Directory(localShareParent).existsSync() ||
            Directory(localShare).existsSync()) {
          return localShare;
        }
        return p.join(home, '.openrom', 'plugins');
      }
    }

    return p.join(Directory.current.path, 'plugins');
  }

  /// The running core version, parsed from the bundled `VERSION` file (or the
  /// explicit override set via [setCoreVersionOverride]).
  SemVer get coreVersion =>
      _coreVersionOverride ??
      SemVer.tryParseLoose(readAppVersion()) ??
      const SemVer(0, 0, 0);

  /// Scans the plugins directory, loads each subfolder containing `plugin.json`,
  /// validates the schema, and registers active plugins in [PluginRegistry].
  ///
  /// Rejects plugins whose `minCoreVersion` is newer than this build.
  Future<void> loadInstalledPlugins() async {
    PluginRegistry.instance.clear();
    final pDir = Directory(pluginsDir);
    if (!pDir.existsSync()) return;

    final entries = pDir.listSync()..sort((a, b) => a.path.compareTo(b.path));
    for (final entry in entries) {
      if (entry is! Directory) continue;
      final name = p.basename(entry.path);
      // Skip our own scratch directories.
      if (name.startsWith('.')) continue;

      final manifestFile = File(p.join(entry.path, 'plugin.json'));
      if (!manifestFile.existsSync()) continue;

      try {
        final jsonMap =
            jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
        final manifest = PluginManifest.fromJson(jsonMap);

        final errors = manifest.validate();
        if (errors.isNotEmpty) {
          logger.log('[PLUGIN WARN] Invalid manifest in ${entry.path}: '
              '${errors.join(', ')}');
          continue;
        }

        final minCore = manifest.minCoreVersion;
        if (minCore != null && coreVersion < minCore) {
          logger.log('[PLUGIN WARN] Skipping ${manifest.id}: requires core '
              '>= $minCore (this build is $coreVersion).');
          continue;
        }

        PluginRegistry.instance.registerPlugin(manifest);
        logger.log('[PLUGIN] Loaded plugin: ${manifest.name} '
            '(${manifest.id}) v${manifest.version}');
      } catch (e) {
        logger.log('[PLUGIN ERROR] Failed to load plugin in ${entry.path}: $e');
      }
    }
  }

  /// Installs a `.orplug` archive from a local path.
  ///
  /// [expectedSha256] / [expectedId] / [expectedVersion] pin the archive to a
  /// trusted registry entry; pass them when installing from the store.
  Future<bool> installPlugin(
    String orplugFilePath, {
    String? expectedSha256,
    String? expectedId,
    SemVer? expectedVersion,
  }) async {
    final result = await installPluginDetailed(
      orplugFilePath,
      expectedSha256: expectedSha256,
      expectedId: expectedId,
      expectedVersion: expectedVersion,
    );
    return result.success;
  }

  /// Like [installPlugin] but returns the full result (manifest or error),
  /// for callers that want a precise failure reason (e.g. the store UI).
  Future<PluginInstallResult> installPluginDetailed(
    String orplugFilePath, {
    String? expectedSha256,
    String? expectedId,
    SemVer? expectedVersion,
  }) async {
    Directory(pluginsDir).createSync(recursive: true);
    final installer = PluginInstaller(
      pluginsDir: pluginsDir,
      coreVersion: coreVersion,
      log: logger.log,
    );
    final result = await installer.installFromArchive(
      orplugFilePath,
      expectedSha256: expectedSha256,
      expectedId: expectedId,
      expectedVersion: expectedVersion,
    );
    if (result.success) {
      await loadInstalledPlugins();
    } else {
      logger.log('[PLUGIN ERROR] Installation refused: ${result.error}');
    }
    return result;
  }

  /// Installs a plugin from already-downloaded (and checksum-verified) bytes.
  Future<PluginInstallResult> installPluginFromBytes(
    List<int> bytes, {
    String? expectedSha256,
    String? expectedId,
    SemVer? expectedVersion,
  }) async {
    Directory(pluginsDir).createSync(recursive: true);
    final installer = PluginInstaller(
      pluginsDir: pluginsDir,
      coreVersion: coreVersion,
      log: logger.log,
    );
    final result = await installer.installFromBytes(
      bytes,
      expectedSha256: expectedSha256,
      expectedId: expectedId,
      expectedVersion: expectedVersion,
    );
    if (result.success) {
      await loadInstalledPlugins();
    }
    return result;
  }

  /// Safely removes the plugin directory and unregisters it.
  Future<bool> uninstallPlugin(String pluginId) async {
    if (!kPluginIdPattern.hasMatch(pluginId)) {
      logger.log('[PLUGIN ERROR] Refusing to uninstall unsafe id "$pluginId".');
      return false;
    }

    final targetPluginDir = Directory(p.join(pluginsDir, pluginId));
    if (!targetPluginDir.existsSync()) {
      logger.log('[PLUGIN WARN] Cannot uninstall: directory not found for '
          'ID "$pluginId"');
      return false;
    }

    try {
      targetPluginDir.deleteSync(recursive: true);
      PluginRegistry.instance.unregisterPlugin(pluginId);
      logger.log('[PLUGIN] Uninstalled plugin "$pluginId"');
      return true;
    } catch (e) {
      logger.log('[PLUGIN ERROR] Failed to uninstall "$pluginId": $e');
      return false;
    }
  }

  /// A configured executor for the current plugins directory.
  PluginExecutor get executor => PluginExecutor(pluginsDir: pluginsDir);

  /// Currently installed/active plugins.
  List<PluginManifest> get installedPlugins =>
      PluginRegistry.instance.activePlugins;
}
