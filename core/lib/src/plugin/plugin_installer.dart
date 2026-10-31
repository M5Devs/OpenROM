// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import 'plugin_manifest.dart';
import 'plugin_version.dart';

/// Result of an installation attempt.
class PluginInstallResult {
  final bool success;
  final PluginManifest? manifest;
  final String? error;

  const PluginInstallResult.success(this.manifest)
      : success = true,
        error = null;

  const PluginInstallResult.failure(this.error)
      : success = false,
        manifest = null;

  @override
  String toString() => success
      ? 'PluginInstallResult.success(${manifest?.id})'
      : 'PluginInstallResult.failure($error)';
}

/// Hard limits to blunt zip-bomb / resource-exhaustion archives.
class PluginArchiveLimits {
  /// Maximum number of entries in a single `.orplug` archive.
  final int maxEntries;

  /// Maximum total uncompressed bytes.
  final int maxTotalBytes;

  /// Maximum uncompressed size of a single entry.
  final int maxEntryBytes;

  const PluginArchiveLimits({
    this.maxEntries = 4096,
    this.maxTotalBytes = 512 * 1024 * 1024, // 512 MiB
    this.maxEntryBytes = 256 * 1024 * 1024, // 256 MiB
  });
}

/// Installs `.orplug` archives safely and atomically.
///
/// Guarantees:
///  * **Zip-Slip protection** — every entry is validated to land inside the
///    staging directory; absolute paths, `..`, drive letters and symlinks are
///    rejected.
///  * **Atomic swap with rollback** — extraction happens in a staging dir on
///    the *same filesystem* as the plugin root, so the final `rename` is
///    atomic. The previous version is moved to a backup dir first and restored
///    if the swap fails; the live install is never left half-written.
///  * **External checksum** — when the caller supplies a trusted SHA-256 (from
///    the registry), it is verified against the raw archive bytes *before*
///    anything is unpacked.
///  * **SemVer gate** — installation is refused when the host core version is
///    lower than the manifest's `minCoreVersion`.
class PluginInstaller {
  final String pluginsDir;
  final SemVer coreVersion;
  final PluginArchiveLimits limits;
  final void Function(String message) log;

  PluginInstaller({
    required this.pluginsDir,
    required this.coreVersion,
    this.limits = const PluginArchiveLimits(),
    void Function(String message)? log,
  }) : log = log ?? _noop;

  static void _noop(String _) {}

  Directory get _stagingRoot => Directory(p.join(pluginsDir, '.staging'));
  Directory get _backupRoot => Directory(p.join(pluginsDir, '.backup'));

  /// Installs a plugin from a local `.orplug` file.
  ///
  /// [expectedSha256] — trusted digest of the archive (from the store
  /// manifest). When provided and mismatched, installation is refused.
  /// [expectedId] / [expectedVersion] — optional pinning so a tampered archive
  /// cannot claim a different identity than the registry advertised.
  Future<PluginInstallResult> installFromArchive(
    String archivePath, {
    String? expectedSha256,
    String? expectedId,
    SemVer? expectedVersion,
  }) async {
    final file = File(archivePath);
    if (!file.existsSync()) {
      return PluginInstallResult.failure(
          'Plugin archive not found: $archivePath');
    }
    final bytes = file.readAsBytesSync();
    return installFromBytes(
      bytes,
      expectedSha256: expectedSha256,
      expectedId: expectedId,
      expectedVersion: expectedVersion,
    );
  }

  /// Installs a plugin from raw archive bytes.
  Future<PluginInstallResult> installFromBytes(
    List<int> bytes, {
    String? expectedSha256,
    String? expectedId,
    SemVer? expectedVersion,
  }) async {
    // 1. Verify the archive against the trusted checksum BEFORE unpacking.
    if (expectedSha256 != null && expectedSha256.trim().isNotEmpty) {
      final actual = sha256.convert(bytes).toString().toLowerCase();
      if (actual != expectedSha256.trim().toLowerCase()) {
        return PluginInstallResult.failure(
          'Archive checksum mismatch (expected ${expectedSha256.trim()}, got $actual).',
        );
      }
    }

    Directory? staging;
    try {
      _stagingRoot.createSync(recursive: true);
      staging = Directory(
        p.join(
          _stagingRoot.path,
          'stage-${DateTime.now().microsecondsSinceEpoch}',
        ),
      )..createSync(recursive: true);

      // 2. Safe extraction.
      final extractError = _extractSafely(bytes, staging);
      if (extractError != null) {
        return PluginInstallResult.failure(extractError);
      }

      // 3. Load + validate the manifest.
      final manifestFile = File(p.join(staging.path, 'plugin.json'));
      if (!manifestFile.existsSync()) {
        return PluginInstallResult.failure(
          'Archive does not contain a "plugin.json" manifest.',
        );
      }

      final PluginManifest manifest;
      try {
        manifest = PluginManifest.fromJson(
          jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>,
        );
      } catch (e) {
        return PluginInstallResult.failure('Malformed "plugin.json": $e');
      }

      final errors = manifest.validate();
      if (errors.isNotEmpty) {
        return PluginInstallResult.failure(
          'Manifest validation failed: ${errors.join('; ')}',
        );
      }

      // 4. Registry pinning (optional).
      if (expectedId != null && expectedId != manifest.id) {
        return PluginInstallResult.failure(
          'Plugin id mismatch: registry advertised "$expectedId" but archive '
          'declares "${manifest.id}".',
        );
      }
      if (expectedVersion != null && expectedVersion != manifest.version) {
        return PluginInstallResult.failure(
          'Plugin version mismatch: registry advertised $expectedVersion but '
          'archive declares ${manifest.version}.',
        );
      }

      // 5. SemVer compatibility gate.
      final minCore = manifest.minCoreVersion;
      if (minCore != null && coreVersion < minCore) {
        return PluginInstallResult.failure(
          'Plugin "${manifest.id}" requires OpenROM core >= $minCore '
          '(this build is $coreVersion).',
        );
      }

      // 6. Verify every declared binary that is present on disk.
      final binaryError = _verifyBinaries(staging, manifest);
      if (binaryError != null) {
        return PluginInstallResult.failure(binaryError);
      }

      // 7. Ensure the host platform actually has a runnable binary.
      if (manifest.execution.kind == PluginExecutionKind.process &&
          !manifest.supportsHostPlatform) {
        return PluginInstallResult.failure(
          'Plugin "${manifest.id}" has no build for platform '
          '"${currentPlatformKey()}".',
        );
      }

      _makeExecutable(staging, manifest);

      // 8. Atomic swap with rollback.
      final swapError = _commit(staging, manifest.id);
      if (swapError != null) {
        return PluginInstallResult.failure(swapError);
      }

      log('[PLUGIN] Installed "${manifest.name}" (${manifest.id}) '
          'v${manifest.version}');
      return PluginInstallResult.success(manifest);
    } catch (e) {
      return PluginInstallResult.failure('Installation failed: $e');
    } finally {
      // Staging is either renamed away (no longer exists) or removed here.
      _deleteQuietly(staging);
    }
  }

  /// Extracts [bytes] into [staging], rejecting unsafe entries.
  /// Returns an error message on failure, or `null` on success.
  String? _extractSafely(List<int> bytes, Directory staging) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (e) {
      return 'Not a valid .orplug (ZIP) archive: $e';
    }

    final root = p.normalize(p.absolute(staging.path));
    var entryCount = 0;
    var totalBytes = 0;

    for (final entry in archive) {
      if (++entryCount > limits.maxEntries) {
        return 'Archive contains too many entries (limit ${limits.maxEntries}).';
      }

      if (entry.isSymbolicLink) {
        return 'Archive contains a symbolic link ("${entry.name}"); refusing to install.';
      }

      final name = entry.name;
      if (name.contains('\u0000')) {
        return 'Archive contains an entry with an illegal null byte.';
      }

      final resolved = p.normalize(p.absolute(p.join(root, name)));
      // Zip-slip guard: must stay strictly inside the staging directory.
      if (resolved != root && !resolved.startsWith(root + p.separator)) {
        return 'Security error: entry escapes the plugin directory ("$name").';
      }

      if (entry.isFile) {
        final content = entry.content as List<int>;
        if (content.length > limits.maxEntryBytes) {
          return 'Archive entry "$name" exceeds the per-file size limit.';
        }
        totalBytes += content.length;
        if (totalBytes > limits.maxTotalBytes) {
          return 'Archive exceeds the total uncompressed size limit.';
        }
        File(resolved)
          ..createSync(recursive: true)
          ..writeAsBytesSync(content);
      } else {
        Directory(resolved).createSync(recursive: true);
      }
    }

    if (entryCount == 0) {
      return 'Archive is empty.';
    }
    return null;
  }

  /// Verifies SHA-256 of every declared binary that exists in [staging].
  String? _verifyBinaries(Directory staging, PluginManifest manifest) {
    for (final entry in manifest.execution.environments.entries) {
      final rel = entry.value.executable;
      if (rel.trim().isEmpty) continue;
      final binPath = p.normalize(p.join(staging.path, rel));
      final root = p.normalize(p.absolute(staging.path));
      if (!p.normalize(p.absolute(binPath)).startsWith(root + p.separator)) {
        return 'Plugin binary "${rel}" escapes the plugin directory.';
      }
      final binFile = File(binPath);
      if (!binFile.existsSync()) {
        // A missing build for a *different* platform is acceptable; a missing
        // build for the host is caught separately by supportsHostPlatform.
        if (entry.key == currentPlatformKey()) {
          return 'Plugin is missing its "${entry.key}" executable ("$rel").';
        }
        continue;
      }
      if (entry.value.sha256.trim().isEmpty) continue;
      final actual = sha256.convert(binFile.readAsBytesSync()).toString();
      if (actual.toLowerCase() != entry.value.sha256.trim().toLowerCase()) {
        return 'SHA-256 mismatch for "${rel}" (expected '
            '${entry.value.sha256.trim()}, got $actual).';
      }
    }
    return null;
  }

  /// Atomically promotes [staging] to `<pluginsDir>/<id>`, keeping a rollback
  /// copy of any previous version. Returns an error message or `null`.
  String? _commit(Directory staging, String pluginId) {
    final target = Directory(p.join(pluginsDir, pluginId));
    final backupRoot = _backupRoot..createSync(recursive: true);
    final backup = Directory(
      p.join(backupRoot.path,
          '$pluginId-${DateTime.now().microsecondsSinceEpoch}'),
    );

    var movedOldToBackup = false;
    try {
      if (target.existsSync()) {
        target.renameSync(backup.path);
        movedOldToBackup = true;
      }
    } catch (e) {
      return 'Could not stage the existing install for replacement: $e';
    }

    try {
      staging.renameSync(target.path);
    } catch (e) {
      // Roll back to the previous version.
      if (movedOldToBackup) {
        try {
          if (target.existsSync()) target.deleteSync(recursive: true);
          backup.renameSync(target.path);
          log('[PLUGIN] Rolled back to previous version of "$pluginId".');
        } catch (rollbackError) {
          return 'Swap failed ($e) and rollback failed ($rollbackError). '
              'Previous version preserved at ${backup.path}.';
        }
      }
      return 'Could not activate the new plugin version: $e';
    }

    // Success — drop the backup.
    if (movedOldToBackup) _deleteQuietly(backup);
    return null;
  }

  void _makeExecutable(Directory staging, PluginManifest manifest) {
    if (Platform.isWindows) return;
    manifest.execution.environments.forEach((key, env) {
      if (env.executable.trim().isEmpty) return;
      final bin = File(p.join(staging.path, env.executable));
      if (bin.existsSync()) {
        try {
          Process.runSync('chmod', ['+x', bin.path]);
        } catch (_) {}
      }
    });
  }

  static void _deleteQuietly(Directory? dir) {
    if (dir == null) return;
    try {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    } catch (_) {}
  }
}
