// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/skin_manifest.dart';
import '../models/theme_config.dart';

/// The outcome of an `.orskin` operation, mirroring the tagged-result style
/// used across OpenROM so callers can distinguish "not found" from "broken".
class SkinResult<T> {
  final T? value;
  final String? error;

  const SkinResult.ok(this.value) : error = null;
  const SkinResult.fail(this.error) : value = null;

  bool get isOk => error == null;
}

/// Installs, exports and removes `.orskin` skin bundles.
///
/// An `.orskin` is a plain ZIP archive:
/// ```
/// my-theme.orskin
/// ├── theme.json      # required — the SkinManifest
/// ├── wallpaper.png   # optional — embedded offline background
/// ├── preview.png     # optional — swatch/screenshot
/// └── README.md       # optional — creator notes
/// ```
///
/// Installed skins live in `<configDir>/themes/<id>/`, each holding the
/// extracted `theme.json` plus any bundled images.
class SkinManager {
  /// Refuse archives larger than this to bound memory during import.
  static const int maxArchiveBytes = 64 * 1024 * 1024;
  static const int maxEntryBytes = 32 * 1024 * 1024;
  static const int maxEntries = 512;

  /// Root directory holding installed skins.
  ///
  /// Defaults to the app support directory resolved once by [init]. Tests (and
  /// callers that manage their own storage) can pass an explicit [configDir].
  final Directory? configDir;

  /// App-wide configuration directory, resolved once at startup by [init].
  static Directory? _configDirCache;

  SkinManager({Directory? configDir})
      : configDir = configDir ?? _configDirCache;

  /// Resolves and caches the app configuration directory. Call once during
  /// startup; it is a no-op if already resolved.
  static Future<Directory> init([Directory? dir]) async {
    _configDirCache ??= dir ?? await getApplicationSupportDirectory();
    return _configDirCache!;
  }

  Directory get _root {
    final dir = configDir;
    if (dir == null) {
      throw StateError(
        'SkinManager has no configuration directory. Call SkinManager.init() '
        'at startup, or pass configDir explicitly.',
      );
    }
    return dir;
  }

  /// `<configDir>/themes` — where installed skins are stored.
  Directory get themesDir => Directory(p.join(_root.path, 'themes'));

  Directory skinDir(String id) =>
      Directory(p.join(themesDir.path, SkinManifest.sanitizeId(id)));

  /// Imports an `.orskin` bundle and returns the installed manifest.
  ///
  /// Extraction is Zip-Slip safe: every entry is canonicalised and must stay
  /// strictly inside the destination directory, symlinks are refused, and both
  /// the entry count and total uncompressed size are bounded.
  Future<SkinResult<SkinManifest>> importSkin(File orskin) async {
    if (!orskin.existsSync()) {
      return SkinResult.fail('File not found: ${orskin.path}');
    }

    final Uint8List bytes;
    try {
      bytes = orskin.readAsBytesSync();
    } catch (e) {
      return SkinResult.fail('Could not read ${orskin.path}: $e');
    }

    if (bytes.length > maxArchiveBytes) {
      return SkinResult.fail('Skin archive is too large (limit 64 MB).');
    }

    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (e) {
      return SkinResult.fail('Not a valid .orskin (ZIP) archive: $e');
    }

    // Resolve theme.json first so the destination dir is derived from the
    // manifest id rather than a caller-supplied name.
    ArchiveFile? manifestEntry;
    for (final entry in archive) {
      if (entry.isFile &&
          p.normalize(entry.name.replaceAll('\\', '/')) == 'theme.json') {
        manifestEntry = entry;
        break;
      }
    }
    if (manifestEntry == null) {
      return SkinResult.fail('Archive does not contain a "theme.json".');
    }

    final SkinManifest manifest;
    try {
      final json = jsonDecode(utf8.decode(manifestEntry.content as List<int>));
      manifest = SkinManifest.fromJson((json as Map).cast<String, dynamic>());
    } catch (e) {
      return SkinResult.fail('Malformed "theme.json": $e');
    }

    final dest = skinDir(manifest.id);
    final root = p.normalize(p.absolute(dest.path));

    // Start from a clean slate so a re-import never leaves stale files.
    if (dest.existsSync()) dest.deleteSync(recursive: true);
    dest.createSync(recursive: true);

    var entryCount = 0;
    var totalBytes = 0;
    for (final entry in archive) {
      if (++entryCount > maxEntries) {
        dest.deleteSync(recursive: true);
        return SkinResult.fail('Archive contains too many entries.');
      }
      if (entry.isSymbolicLink) {
        dest.deleteSync(recursive: true);
        return SkinResult.fail(
          'Archive contains a symbolic link ("${entry.name}"); refusing.',
        );
      }

      final name = entry.name;
      if (name.contains('\u0000')) {
        dest.deleteSync(recursive: true);
        return SkinResult.fail('Archive contains an illegal null byte.');
      }

      final resolved = p.normalize(p.absolute(p.join(root, name)));
      // Zip-Slip guard: must stay strictly inside the destination directory.
      if (resolved != root && !resolved.startsWith(root + p.separator)) {
        dest.deleteSync(recursive: true);
        return SkinResult.fail(
          'Security error: entry escapes the skin directory ("$name").',
        );
      }

      if (entry.isFile) {
        final content = entry.content as List<int>;
        if (content.length > maxEntryBytes) {
          dest.deleteSync(recursive: true);
          return SkinResult.fail('Archive entry "$name" is too large.');
        }
        totalBytes += content.length;
        if (totalBytes > maxArchiveBytes) {
          dest.deleteSync(recursive: true);
          return SkinResult.fail('Archive exceeds the total size limit.');
        }
        File(resolved)
          ..createSync(recursive: true)
          ..writeAsBytesSync(content);
      } else {
        Directory(resolved).createSync(recursive: true);
      }
    }

    // Point the palette at the freshly extracted wallpaper, if any.
    final wallpaper = _findWallpaper(dest);
    final themed = manifest.copyWith(
      theme: manifest.theme.copyWith(
        wallpaperPath: wallpaper?.path,
        clearWallpaper: wallpaper == null,
      ),
    );
    return SkinResult.ok(themed);
  }

  /// Returns the extracted wallpaper image inside [dir], or null.
  File? _findWallpaper(Directory dir) {
    const names = [
      'wallpaper.png',
      'wallpaper.jpg',
      'wallpaper.jpeg',
      'wallpaper.webp',
      'wallpaper.bmp',
    ];
    for (final name in names) {
      final file = File(p.join(dir.path, name));
      if (file.existsSync()) return file;
    }
    return null;
  }

  /// Packs [theme] (plus an optional [wallpaper] and [preview] image) into an
  /// `.orskin` bundle at [outputPath].
  ///
  /// Returns the written file on success.
  SkinResult<File> exportSkin({
    required ThemeConfig theme,
    required File outputPath,
    File? wallpaper,
    File? preview,
    String? id,
    String? author,
    String? version,
    String? readme,
  }) {
    final manifest = SkinManifest.fromTheme(
      theme,
      id: id,
      author: author,
      version: version,
    );

    final archive = Archive();
    final manifestBytes = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
    );
    archive.addFile(
      ArchiveFile('theme.json', manifestBytes.length, manifestBytes),
    );

    if (wallpaper != null && wallpaper.existsSync()) {
      final data = wallpaper.readAsBytesSync();
      final ext = p.extension(wallpaper.path).toLowerCase();
      final safeExt = ext.isEmpty ? '.png' : ext;
      archive.addFile(
        ArchiveFile('wallpaper$safeExt', data.length, data),
      );
    }

    if (preview != null && preview.existsSync()) {
      final data = preview.readAsBytesSync();
      final ext = p.extension(preview.path).toLowerCase();
      final safeExt = ext.isEmpty ? '.png' : ext;
      archive.addFile(ArchiveFile('preview$safeExt', data.length, data));
    }

    final readmeText = readme ?? _defaultReadme(manifest);
    final readmeBytes = utf8.encode(readmeText);
    archive.addFile(
      ArchiveFile('README.md', readmeBytes.length, readmeBytes),
    );

    try {
      final encoded = ZipEncoder().encode(archive);
      if (encoded == null) {
        return const SkinResult.fail('Failed to encode the .orskin archive.');
      }
      outputPath.parent.createSync(recursive: true);
      outputPath.writeAsBytesSync(encoded);
      return SkinResult.ok(outputPath);
    } catch (e) {
      return SkinResult.fail('Failed to write ${outputPath.path}: $e');
    }
  }

  /// Removes an installed skin by [id]. Returns true if something was deleted.
  bool removeSkin(String id) {
    final dir = skinDir(id);
    if (!dir.existsSync()) return false;
    dir.deleteSync(recursive: true);
    return true;
  }

  /// Lists every installed skin.
  ///
  /// Returns an empty list when no configuration directory has been resolved
  /// yet (e.g. in unit tests that never call [init]) rather than throwing, so
  /// [ThemeService] construction stays safe everywhere.
  List<SkinManifest> listInstalledSkins() {
    final result = <SkinManifest>[];
    if (configDir == null) return result;
    final root = themesDir;
    if (!root.existsSync()) return result;

    for (final entry in root.listSync()) {
      if (entry is! Directory) continue;
      final manifest = File(p.join(entry.path, 'theme.json'));
      if (!manifest.existsSync()) continue;
      try {
        final json =
            jsonDecode(manifest.readAsStringSync()) as Map<String, dynamic>;
        final skin = SkinManifest.fromJson(json);
        final wallpaper = _findWallpaper(entry);
        result.add(
          skin.copyWith(
            theme: skin.theme.copyWith(
              wallpaperPath: wallpaper?.path,
              clearWallpaper: wallpaper == null,
            ),
          ),
        );
      } catch (e) {
        debugPrint('Skipping unreadable skin at ${entry.path}: $e');
      }
    }
    return result;
  }

  static String _defaultReadme(SkinManifest manifest) => '''
# ${manifest.name}

An OpenROM skin by ${manifest.author}.

- **id:** `${manifest.id}`
- **version:** ${manifest.version}
- **mode:** ${manifest.mode}

Install this `.orskin` from OpenROM via **Theme Editor → Import .orskin**, or
drag the file onto the application window.
''';
}
