// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;

/// Shared "no 7-Zip installed" failure message.
const String sevenZipNotFoundMessage =
    '7-Zip executable not found. Install 7-Zip (7zz/7z) or set OPENROM_7Z.';

/// One entry parsed from `7z l -slt` output.
class SevenZipEntry {
  final String path;
  final String attributes;
  final String method;
  final String encrypted;
  final String size;

  const SevenZipEntry({
    required this.path,
    this.attributes = '',
    this.method = '',
    this.encrypted = '',
    this.size = '',
  });

  /// True when the entry is a directory (`Attributes` starts with `D`).
  bool get isDirectory => attributes.trimLeft().startsWith('D');

  /// True when 7-Zip flagged the entry as encrypted.
  bool get isEncrypted => encrypted.trim() == '+';

  @override
  String toString() => 'SevenZipEntry($path)';
}

/// The result of parsing a `7z l -slt` listing.
class SevenZipListing {
  /// Entries after the `----------` separator (real archive members).
  final List<SevenZipEntry> entries;

  /// True when the header block before the separator reported encryption.
  final bool headerEncrypted;

  const SevenZipListing(this.entries, {this.headerEncrypted = false});

  bool get isEmpty => entries.isEmpty;
}

/// Parses the entry blocks of a `7z l -slt` listing.
///
/// Pure and side-effect free, so it can be unit-tested with captured output.
/// Only blocks after the `----------` separator line are considered; the header
/// block that precedes it also carries a `Path =` line (the archive itself)
/// which is not an archive member.
SevenZipListing parseSevenZipListing(String output) {
  final lines = output.split(RegExp(r'\r?\n'));

  // 1) Header block up to and including the separator line.
  var i = 0;
  var headerEncrypted = false;
  for (; i < lines.length; i++) {
    final t = lines[i].trim();
    if (RegExp(r'^-{3,}$').hasMatch(t)) {
      i++;
      break;
    }
    if (t.startsWith('Encrypted =') &&
        t.substring('Encrypted ='.length).trim() == '+') {
      headerEncrypted = true;
    }
  }

  // 2) Entry blocks after the separator.
  final entries = <SevenZipEntry>[];
  String? path;
  String attributes = '';
  String method = '';
  String encrypted = '';
  String size = '';

  void flush() {
    if (path != null && path!.isNotEmpty) {
      entries.add(SevenZipEntry(
        path: path!,
        attributes: attributes,
        method: method,
        encrypted: encrypted,
        size: size,
      ));
    }
    path = null;
    attributes = '';
    method = '';
    encrypted = '';
    size = '';
  }

  for (; i < lines.length; i++) {
    final t = lines[i].trim();
    if (t.isEmpty || t == '----------') {
      flush();
      continue;
    }
    final eq = t.indexOf(' = ');
    if (eq < 0) continue;
    final key = t.substring(0, eq).trim();
    final value = t.substring(eq + 3);
    switch (key) {
      case 'Path':
        // A new `Path` starts a new block; flush the previous one.
        if (path != null) flush();
        path = value;
        break;
      case 'Attributes':
        attributes = value;
        break;
      case 'Method':
        method = value;
        break;
      case 'Encrypted':
        encrypted = value;
        break;
      case 'Size':
        size = value;
        break;
    }
  }
  flush();

  return SevenZipListing(entries, headerEncrypted: headerEncrypted);
}

/// Thin, shell-free wrapper around an installed 7-Zip executable.
///
/// Security properties:
///  * **No shell.** Every invocation goes through
///    `Process.runSync(exe, argvList, ...)`; there is no string building, no
///    `runInShell`, and no `sh -c`.
///  * **No option injection.** `--` always precedes user-controlled paths, so
///    a name such as `-evil.bin` can never be parsed as a 7-Zip switch.
///  * **No passwords.** Passwords are never passed (nor `-p`-style switches);
///    encrypted archives are rejected up front instead.
///  * **Strict success.** Only exit code 0 counts as success; exit 1 (warning)
///    is a failure carrying the stderr tail.
class SevenZip {
  /// Absolute path (or PATH-resolvable name) of the 7-Zip executable.
  final String executable;

  /// Optional sink for human-readable diagnostics.
  final void Function(String message)? onLog;

  const SevenZip(this.executable, {this.onLog});

  /// Level name -> `-mx` switch value.
  static const Map<String, String> _levelMap = {
    'fast': '1',
    'normal': '5',
    'ultra': '9',
  };

  /// Maps a UI level string to its `-mx` value, defaulting to normal.
  static String compressionLevel(String level) =>
      _levelMap[level.toLowerCase()] ?? _levelMap['normal']!;

  /// Locates a usable 7-Zip executable, or returns `null`.
  ///
  /// Search order:
  ///  1. `$OPENROM_7Z` (ignored with a log line when it is not an existing
  ///     file),
  ///  2. `7zz`, `7z`, `7za`, `7zr` (plus `.exe` on Windows) on `PATH`,
  ///  3. Windows only: `%ProgramFiles%\7-Zip\7z.exe` and the `(x86)` variant.
  ///
  /// No `which`/`where` subprocess is spawned: `PATH` entries are scanned
  /// directly with `File.existsSync`.
  static String? locate({
    Map<String, String>? environment,
    void Function(String message)? onLog,
  }) {
    final env = environment ?? Platform.environment;

    final override = env['OPENROM_7Z'];
    if (override != null && override.isNotEmpty) {
      if (File(override).existsSync()) {
        return override;
      }
      onLog?.call(
        '[7Z] OPENROM_7Z is set to "$override" but that file does not exist; '
        'falling back to PATH lookup.',
      );
    }

    final names = <String>['7zz', '7z', '7za', '7zr'];
    final candidates = Platform.isWindows
        ? [for (final n in names) '$n.exe', ...names]
        : names;

    final pathVar = env['PATH'] ?? env['Path'] ?? '';
    final sep = Platform.isWindows ? ';' : ':';
    for (final dir in pathVar.split(sep)) {
      if (dir.trim().isEmpty) continue;
      for (final name in candidates) {
        final full = p.join(dir, name);
        if (File(full).existsSync()) return full;
      }
    }

    if (Platform.isWindows) {
      for (final key in ['ProgramFiles', 'ProgramFiles(x86)']) {
        final base = env[key];
        if (base == null || base.isEmpty) continue;
        final full = p.join(base, '7-Zip', '7z.exe');
        if (File(full).existsSync()) return full;
      }
    }

    return null;
  }

  /// True when [path] is a directory component that must be rejected.
  static bool _isUnsafeEntryPath(String raw) {
    if (raw.isEmpty) return true;
    if (raw.contains('\u0000')) return true;
    if (raw.startsWith('/') || raw.startsWith('\\')) return true;
    // Windows drive letter, e.g. `C:` or `C:\x`.
    if (RegExp(r'^[a-zA-Z]:').hasMatch(raw)) return true;
    // Any `..` component, on either separator.
    final parts = raw.split(RegExp(r'[\\/]+'));
    if (parts.contains('..')) return true;
    return false;
  }

  /// Lists the entries of [archive] (thin wrapper used by tests/tools).
  static SevenZipListing parseListing(String output) =>
      parseSevenZipListing(output);

  /// Lists [archive] and rejects it when any entry path is unsafe.
  ///
  /// Returns `null` on success, or a human-readable error message when the
  /// archive is unsafe, encrypted, or cannot be read.
  String? _safetyError(SevenZipListing listing) {
    if (listing.headerEncrypted || listing.entries.any((e) => e.isEncrypted)) {
      return 'encrypted archives are not supported';
    }
    for (final entry in listing.entries) {
      if (_isUnsafeEntryPath(entry.path)) {
        return 'unsafe path in archive: ${entry.path}';
      }
    }
    return null;
  }

  static String _tail(String text, [int lines = 20]) {
    final all = text.split(RegExp(r'\r?\n'));
    final trimmed = all.length > lines ? all.sublist(all.length - lines) : all;
    return trimmed.join('\n').trim();
  }

  /// Heuristic: 7-Zip prompts for a password on stdout when a header-encrypted
  /// archive is opened, and `Process.runSync` closes stdin so it fails fast.
  static bool _looksEncrypted(String text) =>
      text.toLowerCase().contains('password');

  bool get _executableExists => File(executable).existsSync();

  /// Compresses [source] into a fresh `<baseName>.7z` inside [outputDir].
  ///
  /// [source] may be a file or a directory. Returns `null` on success, or an
  /// error message on failure. Any partial archive is removed on failure and a
  /// pre-existing `<baseName>.7z` is left untouched.
  String? compress({
    required String source,
    required String outputDir,
    required String level,
  }) {
    final absSource = p.canonicalize(source);
    final baseName = p.basename(absSource);
    final parent = p.dirname(absSource);
    final finalPath = p.join(outputDir, '$baseName.7z');

    // 7z appends to an existing archive, so always build a fresh temp file.
    final tmpPath = p.join(outputDir, '$baseName.7z.part-$pid');

    if (File(tmpPath).existsSync()) {
      File(tmpPath).deleteSync();
    }

    if (!_executableExists) {
      return sevenZipNotFoundMessage;
    }

    final mx = compressionLevel(level);
    if (!_levelMap.containsKey(level.toLowerCase())) {
      onLog?.call('[7Z] Unknown level "$level"; using normal (-mx=$mx).');
    }

    final argv = <String>[
      'a',
      '-t7z',
      '-mx=$mx',
      '-y',
      '-bd',
      '-bso0',
      '--',
      tmpPath,
      baseName,
    ];

    ProcessResult result;
    try {
      result = Process.runSync(executable, argv, workingDirectory: parent);
    } on ProcessException {
      _cleanup(tmpPath);
      return sevenZipNotFoundMessage;
    } catch (e) {
      _cleanup(tmpPath);
      return 'Failed to launch 7-Zip: $e';
    }

    if (result.exitCode != 0) {
      final detail = _tail('${result.stderr}\n${result.stdout}');
      _cleanup(tmpPath);
      return '7-Zip failed (exit ${result.exitCode})'
          '${detail.isEmpty ? '' : ': $detail'}';
    }

    if (!File(tmpPath).existsSync()) {
      return '7-Zip reported success but produced no archive.';
    }

    try {
      final existing = File(finalPath);
      if (existing.existsSync()) existing.deleteSync();
      File(tmpPath).renameSync(finalPath);
    } catch (e) {
      _cleanup(tmpPath);
      return 'Failed to finalise archive: $e';
    }

    return null;
  }

  /// Extracts [archive] into [outputDir].
  ///
  /// Returns `null` on success, or an error message on failure. Nothing is
  /// moved into [outputDir] unless the archive passed the listing safety check
  /// and extraction produced no links or escaping paths.
  String? extract({required String archive, required String outputDir}) {
    final absArchive = p.canonicalize(archive);

    if (!_executableExists) {
      return sevenZipNotFoundMessage;
    }

    ProcessResult listResult;
    try {
      listResult = Process.runSync(
        executable,
        ['l', '-slt', '-y', '--', absArchive],
      );
    } on ProcessException {
      return sevenZipNotFoundMessage;
    } catch (e) {
      return 'Failed to launch 7-Zip: $e';
    }
    if (listResult.exitCode != 0) {
      if (_looksEncrypted('${listResult.stdout}\n${listResult.stderr}')) {
        return 'encrypted archives are not supported';
      }
      final detail = _tail('${listResult.stderr}\n${listResult.stdout}');
      return '7-Zip could not read the archive (exit ${listResult.exitCode})'
          '${detail.isEmpty ? '' : ': $detail'}';
    }

    final listing = parseListing('${listResult.stdout}');
    final safety = _safetyError(listing);
    if (safety != null) return safety;

    final staging = Directory(p.join(
      outputDir,
      '.openrom-extract-${Random().nextInt(1 << 32).toRadixString(16)}',
    ));

    try {
      staging.createSync(recursive: true);
      final stagingRoot = p.canonicalize(staging.path);

      ProcessResult extractResult;
      try {
        extractResult = Process.runSync(
          executable,
          ['x', '-y', '-bd', '-o$stagingRoot', '--', absArchive],
        );
      } on ProcessException {
        return sevenZipNotFoundMessage;
      } catch (e) {
        return 'Failed to launch 7-Zip: $e';
      }

      if (extractResult.exitCode != 0) {
        final detail =
            _tail('${extractResult.stderr}\n${extractResult.stdout}');
        return '7-Zip extraction failed (exit ${extractResult.exitCode})'
            '${detail.isEmpty ? '' : ': $detail'}';
      }

      final guard = _stagingGuardError(stagingRoot);
      if (guard != null) return guard;

      return _moveStaged(stagingRoot, p.canonicalize(outputDir));
    } catch (e) {
      return 'Extraction failed: $e';
    } finally {
      _deleteDir(staging);
    }
  }

  /// Rejects any link or escaping path inside [stagingRoot].
  String? _stagingGuardError(String stagingRoot) {
    final prefix = stagingRoot.endsWith(p.separator)
        ? stagingRoot
        : stagingRoot + p.separator;

    final entities = Directory(stagingRoot).listSync(
      recursive: true,
      followLinks: false,
    );

    for (final entity in entities) {
      if (entity is Link) {
        return 'archive contains a symbolic link: ${entity.path}';
      }
      String resolved;
      try {
        resolved = entity.resolveSymbolicLinksSync();
      } catch (_) {
        continue; // broken link already rejected above
      }
      if (resolved != stagingRoot && !resolved.startsWith(prefix)) {
        return 'archive entry escapes the extraction directory: '
            '${entity.path}';
      }
    }
    return null;
  }

  /// Moves every file from [stagingRoot] into [outputDir].
  String? _moveStaged(String stagingRoot, String outputDir) {
    final entities = Directory(stagingRoot).listSync(
      recursive: true,
      followLinks: false,
    );

    for (final entity in entities) {
      if (entity is! File) continue;
      final rel = p.relative(entity.path, from: stagingRoot);
      final dest = p.join(outputDir, rel);
      final destFile = File(dest);
      final parentDir = Directory(p.dirname(dest));
      if (!parentDir.existsSync()) {
        parentDir.createSync(recursive: true);
      }
      if (destFile.existsSync()) destFile.deleteSync();
      try {
        entity.renameSync(dest);
      } on FileSystemException {
        // Cross-device or otherwise non-atomic: fall back to copy + delete.
        entity.copySync(dest);
        entity.deleteSync();
      }
    }
    return null;
  }

  void _cleanup(String path) {
    final f = File(path);
    try {
      if (f.existsSync()) f.deleteSync();
    } catch (_) {}
  }

  void _deleteDir(Directory dir) {
    try {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    } catch (_) {}
  }
}
