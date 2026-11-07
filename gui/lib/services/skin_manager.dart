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
/// An `.orskin` is a plain ZIP archive. v2 bundles may carry any of:
/// ```
/// my-theme.orskin
/// ├── skin.json          # required — the SkinManifest (v1 name: theme.json)
/// ├── wallpaper.gif|png  # optional — animated or static background
/// ├── dropzone.gif|png   # optional — custom dropzone illustration
/// ├── font.ttf|otf       # optional — runtime-loaded UI font
/// ├── icons/<tab>.png    # optional — sidebar icon overrides
/// ├── preview.png        # optional — storefront screenshot
/// └── README.md          # optional — creator notes
/// ```
///
/// Installed skins live in `<configDir>/themes/<id>/`, each holding the
/// extracted manifest plus any bundled assets.
class SkinManager {
  /// Refuse archives larger than this to bound memory during import.
  static const int maxArchiveBytes = 64 * 1024 * 1024;
  static const int maxEntryBytes = 32 * 1024 * 1024;
  static const int maxEntries = 512;

  /// Image extensions accepted for wallpapers and dropzones.
  static const List<String> imageExtensions = [
    'gif',
    'webp',
    'png',
    'jpg',
    'jpeg'
  ];

  /// Font extensions accepted for the runtime-loaded UI font.
  static const List<String> fontExtensions = ['ttf', 'otf'];

  /// Fixed timestamp baked into exported archives so identical inputs always
  /// produce a byte-identical `.orskin` (deterministic builds).
  static final DateTime _epoch = DateTime.utc(1980, 1, 1);

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

    // Resolve the manifest first so the destination dir is derived from the
    // manifest id rather than a caller-supplied name. v2 bundles name it
    // "skin.json"; v1 bundles named it "theme.json".
    ArchiveFile? manifestEntry;
    for (final entry in archive) {
      if (!entry.isFile) continue;
      final normalized = p.normalize(entry.name.replaceAll('\\', '/'));
      if (normalized == 'skin.json' || normalized == 'theme.json') {
        // Prefer skin.json if a (malformed) archive contains both.
        if (manifestEntry == null || normalized == 'skin.json') {
          manifestEntry = entry;
        }
        if (normalized == 'skin.json') break;
      }
    }
    if (manifestEntry == null) {
      return SkinResult.fail(
        'Archive does not contain a "skin.json" (or legacy "theme.json").',
      );
    }

    final SkinManifest manifest;
    try {
      final json = jsonDecode(utf8.decode(manifestEntry.content as List<int>));
      manifest = SkinManifest.fromJson((json as Map).cast<String, dynamic>());
    } catch (e) {
      return SkinResult.fail('Malformed "${manifestEntry.name}": $e');
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

    // Point the palette at the freshly extracted assets, if any.
    return SkinResult.ok(_applyAssets(manifest, dest));
  }

  /// Resolves the v2 assets inside an extracted skin [dir] onto [manifest]'s
  /// theme, clearing any that are absent so a re-import never leaves a stale
  /// path behind.
  SkinManifest _applyAssets(SkinManifest manifest, Directory dir) {
    final wallpaper = _findAsset(dir, 'wallpaper');
    final dropzone = _findAsset(dir, 'dropzone');
    final font = manifest.hasCustomFont
        ? _findFont(dir, manifest.fontFileName)
        : _findAssetOfType(dir, 'font', fontExtensions);
    final iconDir = _findIconDir(dir);

    return manifest.copyWith(
      theme: manifest.theme.copyWith(
        wallpaperPath: wallpaper?.path,
        clearWallpaper: wallpaper == null,
        dropzonePath: dropzone?.path,
        clearDropzone: dropzone == null,
        fontPath: font?.path,
        clearFont: font == null,
        iconDir: iconDir?.path,
        clearIconDir: iconDir == null,
      ),
    );
  }

  /// Returns `<dir>/<base>.<ext>` for the first supported [imageExtensions].
  File? _findAsset(Directory dir, String base) =>
      _findAssetOfType(dir, base, imageExtensions);

  File? _findAssetOfType(
    Directory dir,
    String base,
    List<String> extensions,
  ) {
    for (final ext in extensions) {
      final file = File(p.join(dir.path, '$base.$ext'));
      if (file.existsSync()) return file;
    }
    return null;
  }

  /// Locates the custom font. When the manifest names it ([fileName]) that exact
  /// (basename-sanitised) file is used; otherwise any `font.<ext>` is accepted.
  File? _findFont(Directory dir, String? fileName) {
    if (fileName != null && fileName.isNotEmpty) {
      final safe = p.basename(fileName.replaceAll('\\', '/'));
      final file = File(p.join(dir.path, safe));
      if (file.existsSync()) return file;
    }
    return _findAssetOfType(dir, 'font', fontExtensions);
  }

  /// Returns `<dir>/icons` when it holds at least one icon, else null.
  Directory? _findIconDir(Directory dir) {
    final icons = Directory(p.join(dir.path, 'icons'));
    if (!icons.existsSync()) return null;
    final hasAny = icons
        .listSync()
        .whereType<File>()
        .any((f) => p.extension(f.path).toLowerCase() == '.png');
    return hasAny ? icons : null;
  }

  /// Packs [theme] (plus any of the v2 assets: [wallpaper], [dropzone],
  /// [font], [iconsDir] and [preview]) into an `.orskin` bundle at
  /// [outputPath].
  ///
  /// The manifest is written as `skin.json` (v2). Assets are stored under their
  /// canonical names (`wallpaper.<ext>`, `dropzone.<ext>`, `font.<ext>`,
  /// `icons/<tab>.png`) so import can find them regardless of the source file
  /// name. The archive is deterministic: entries are sorted and stamped with a
  /// fixed timestamp, so identical inputs always yield identical bytes.
  ///
  /// Returns the written file on success.
  SkinResult<File> exportSkin({
    required ThemeConfig theme,
    required File outputPath,
    File? wallpaper,
    File? dropzone,
    File? font,
    Directory? iconsDir,
    File? preview,
    String? id,
    String? author,
    String? version,
    String? readme,
  }) {
    // Resolve assets from explicit arguments, falling back to the theme's own
    // paths (so exporting the currently-applied skin just works).
    final resolvedWallpaper = wallpaper ?? _existingFile(theme.wallpaperPath);
    final resolvedDropzone = dropzone ?? _existingFile(theme.dropzonePath);
    final resolvedFont = font ?? _existingFile(theme.fontPath);
    final resolvedIcons =
        iconsDir ?? (theme.iconDir == null ? null : Directory(theme.iconDir!));

    final manifest = SkinManifest.fromTheme(
      theme,
      id: id,
      author: author,
      version: version,
    ).copyWith(
      hasCustomFont: resolvedFont != null,
      clearFontFileName: resolvedFont == null,
      fontFileName: resolvedFont == null
          ? null
          : 'font${_safeExtension(resolvedFont.path, fontExtensions)}',
      hasCustomIcons: _hasPng(resolvedIcons),
      hasCustomDropzone: resolvedDropzone != null,
    );

    // Collect entries, then add them in sorted order so the archive is
    // deterministic regardless of the order assets were supplied.
    final manifestBytes = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
    );
    final entries = <MapEntry<String, List<int>>>[
      MapEntry('skin.json', manifestBytes),
    ];

    if (resolvedWallpaper != null) {
      final ext = _safeExtension(resolvedWallpaper.path, imageExtensions);
      entries
          .add(MapEntry('wallpaper$ext', resolvedWallpaper.readAsBytesSync()));
    }

    if (resolvedDropzone != null) {
      final ext = _safeExtension(resolvedDropzone.path, imageExtensions);
      entries.add(MapEntry('dropzone$ext', resolvedDropzone.readAsBytesSync()));
    }

    if (resolvedFont != null) {
      final ext = _safeExtension(resolvedFont.path, fontExtensions);
      entries.add(MapEntry('font$ext', resolvedFont.readAsBytesSync()));
    }

    if (resolvedIcons != null && resolvedIcons.existsSync()) {
      final pngs = resolvedIcons
          .listSync()
          .whereType<File>()
          .where((f) => p.extension(f.path).toLowerCase() == '.png')
          .toList()
        ..sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));
      for (final icon in pngs) {
        final name = p.basename(icon.path);
        if (!SkinManifest.tabIds.contains(p.basenameWithoutExtension(name))) {
          continue;
        }
        entries.add(MapEntry('icons/$name', icon.readAsBytesSync()));
      }
    }

    if (preview != null && preview.existsSync()) {
      final ext = _safeExtension(preview.path, imageExtensions);
      entries.add(MapEntry('preview$ext', preview.readAsBytesSync()));
    }

    entries.add(
        MapEntry('README.md', utf8.encode(readme ?? _defaultReadme(manifest))));
    entries.sort((a, b) => a.key.compareTo(b.key));

    final archive = Archive();
    for (final e in entries) {
      archive.addFile(ArchiveFile(e.key, e.value.length, e.value));
    }

    try {
      // Deterministic: entries already sorted + a fixed modification timestamp.
      final encoded = ZipEncoder().encode(archive, modified: _epoch);
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

  File? _existingFile(String? path) {
    if (path == null || path.isEmpty) return null;
    final file = File(path);
    return file.existsSync() ? file : null;
  }

  static bool _hasPng(Directory? dir) {
    if (dir == null || !dir.existsSync()) return false;
    return dir
        .listSync()
        .whereType<File>()
        .any((f) => p.extension(f.path).toLowerCase() == '.png');
  }

  /// Returns [path]'s extension when it is one of [allowed], else the first
  /// allowed extension as a safe default.
  static String _safeExtension(String path, List<String> allowed) {
    final ext = p.extension(path).toLowerCase().replaceFirst('.', '');
    return allowed.contains(ext) ? '.$ext' : '.${allowed.first}';
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
      // v2 skins use skin.json; v1 skins used theme.json.
      final skinJson = File(p.join(entry.path, 'skin.json'));
      final legacyJson = File(p.join(entry.path, 'theme.json'));
      final manifest = skinJson.existsSync()
          ? skinJson
          : (legacyJson.existsSync() ? legacyJson : null);
      if (manifest == null) continue;
      try {
        final json =
            jsonDecode(manifest.readAsStringSync()) as Map<String, dynamic>;
        final skin = SkinManifest.fromJson(json);
        result.add(_applyAssets(skin, entry));
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
