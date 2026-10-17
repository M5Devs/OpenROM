// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../logger.dart' as logger;
import 'plugin_manifest.dart';
import 'plugin_registry.dart';

class PluginManager {
  static final PluginManager instance = PluginManager._internal();

  PluginManager._internal();

  String? _customPluginsDir;

  void setCustomPluginsDir(String? dirPath) {
    _customPluginsDir = dirPath;
  }

  /// Resolves the user storage directory for plugins:
  /// - Windows: %APPDATA%\OpenROM\plugins\
  /// - Linux/macOS: ~/.local/share/openrom/plugins/ (fallback ~/.openrom/plugins/)
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

  /// Scans the plugins directory, loads each subfolder containing `plugin.json`,
  /// validates the schema, and registers active plugins in `PluginRegistry`.
  Future<void> loadInstalledPlugins() async {
    PluginRegistry.instance.clear();
    final pDir = Directory(pluginsDir);
    if (!pDir.existsSync()) {
      return;
    }

    final entries = pDir.listSync();
    for (final entry in entries) {
      if (entry is Directory) {
        final manifestFile = File(p.join(entry.path, 'plugin.json'));
        if (manifestFile.existsSync()) {
          try {
            final jsonStr = manifestFile.readAsStringSync();
            final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
            final manifest = PluginManifest.fromJson(jsonMap);
            final errors = manifest.validate();
            if (errors.isEmpty) {
              PluginRegistry.instance.registerPlugin(manifest);
              logger.log(
                  '[PLUGIN] Loaded plugin: ${manifest.name} (${manifest.id}) v${manifest.version}');
            } else {
              logger.log(
                  '[PLUGIN WARN] Invalid plugin manifest in ${entry.path}: ${errors.join(", ")}');
            }
          } catch (e) {
            logger.log(
                '[PLUGIN ERROR] Failed to load plugin in ${entry.path}: $e');
          }
        }
      }
    }
  }

  /// Installs a plugin from a `.orplug` archive file.
  /// 1. Extracts the ZIP archive into `<plugins_dir>/<plugin_id>/`.
  /// 2. Validates `plugin.json`.
  /// 3. Verifies the SHA256 of the current platform binary (if included/specified).
  /// 4. Sets executable permission on non-Windows platforms.
  /// 5. Refuses installation if corrupted or manifest is invalid.
  Future<bool> installPlugin(String orplugFilePath) async {
    final file = File(orplugFilePath);
    if (!file.existsSync()) {
      logger
          .log('[PLUGIN ERROR] Plugin archive file not found: $orplugFilePath');
      return false;
    }

    final tempExtractDir =
        Directory.systemTemp.createTempSync('openrom_plugin_extract_');
    try {
      final bytes = file.readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      final basePath = p.normalize(p.canonicalize(tempExtractDir.path));

      for (final archiveFile in archive) {
        final destPath = p.normalize(p.join(basePath, archiveFile.name));
        if (!destPath.startsWith(basePath + p.separator) &&
            destPath != basePath) {
          logger.log(
              '[PLUGIN ERROR] Security error: Malicious zip entry in archive: ${archiveFile.name}');
          return false;
        }

        if (archiveFile.isFile) {
          final data = archiveFile.content as List<int>;
          File(destPath)
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        } else {
          Directory(destPath).createSync(recursive: true);
        }
      }

      final manifestFile = File(p.join(tempExtractDir.path, 'plugin.json'));
      if (!manifestFile.existsSync()) {
        logger.log(
            '[PLUGIN ERROR] Archive does not contain a valid "plugin.json" manifest.');
        return false;
      }

      final jsonStr = manifestFile.readAsStringSync();
      final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
      final manifest = PluginManifest.fromJson(jsonMap);

      final errors = manifest.validate();
      if (errors.isNotEmpty) {
        logger.log(
            '[PLUGIN ERROR] Manifest validation failed: ${errors.join("; ")}');
        return false;
      }

      // Verify SHA256 of current platform binary if specified
      final platformBin = manifest.currentPlatformBinary;
      if (platformBin != null && platformBin.executable.isNotEmpty) {
        final binFile =
            File(p.join(tempExtractDir.path, platformBin.executable));
        if (!binFile.existsSync()) {
          logger.log(
              '[PLUGIN ERROR] Missing expected platform executable: ${platformBin.executable}');
          return false;
        }

        if (platformBin.sha256.isNotEmpty) {
          final binBytes = binFile.readAsBytesSync();
          final computedDigest =
              sha256.convert(binBytes).toString().toLowerCase();
          final expectedDigest = platformBin.sha256.trim().toLowerCase();

          if (computedDigest != expectedDigest) {
            logger.log(
              '[PLUGIN ERROR] SHA256 mismatch for ${platformBin.executable}. '
              'Expected: $expectedDigest, Got: $computedDigest',
            );
            return false;
          }
        }

        // Ensure executable permissions on Unix systems
        if (!Platform.isWindows) {
          try {
            Process.runSync('chmod', ['+x', binFile.path]);
          } catch (_) {}
        }
      }

      final targetPluginDir = Directory(p.join(pluginsDir, manifest.id));
      if (targetPluginDir.existsSync()) {
        targetPluginDir.deleteSync(recursive: true);
      }
      targetPluginDir.createSync(recursive: true);

      _copyDirectorySync(tempExtractDir, targetPluginDir);

      // Reload installed plugins into registry
      await loadInstalledPlugins();
      logger.log(
          '[PLUGIN] Successfully installed plugin "${manifest.name}" (${manifest.id})');
      return true;
    } catch (e) {
      logger.log('[PLUGIN ERROR] Plugin installation failed: $e');
      return false;
    } finally {
      try {
        if (tempExtractDir.existsSync()) {
          tempExtractDir.deleteSync(recursive: true);
        }
      } catch (_) {}
    }
  }

  /// Safely removes the plugin directory and unregisters it.
  Future<bool> uninstallPlugin(String pluginId) async {
    final targetPluginDir = Directory(p.join(pluginsDir, pluginId));
    if (!targetPluginDir.existsSync()) {
      logger.log(
          '[PLUGIN WARN] Cannot uninstall: Plugin directory not found for ID "$pluginId"');
      return false;
    }

    try {
      targetPluginDir.deleteSync(recursive: true);
      PluginRegistry.instance.unregisterPlugin(pluginId);
      logger.log('[PLUGIN] Successfully uninstalled plugin "$pluginId"');
      return true;
    } catch (e) {
      logger.log('[PLUGIN ERROR] Failed to uninstall plugin "$pluginId": $e');
      return false;
    }
  }

  /// Exposes currently installed/active plugins from registry.
  List<PluginManifest> get installedPlugins =>
      PluginRegistry.instance.activePlugins;

  void _copyDirectorySync(Directory source, Directory destination) {
    for (final entity in source.listSync(recursive: false)) {
      final name = p.basename(entity.path);
      final destPath = p.join(destination.path, name);
      if (entity is Directory) {
        final newDir = Directory(destPath)..createSync(recursive: true);
        _copyDirectorySync(entity, newDir);
      } else if (entity is File) {
        entity.copySync(destPath);
        if (!Platform.isWindows) {
          try {
            final stat = entity.statSync();
            final isExecutable = (stat.mode & 0x49) !=
                0; // Check executable bits (S_IXUSR, S_IXGRP, S_IXOTH)
            if (isExecutable) {
              Process.runSync('chmod', ['+x', destPath]);
            }
          } catch (_) {}
        }
      }
    }
  }
}
