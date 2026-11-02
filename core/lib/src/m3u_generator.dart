// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:io';

import 'package:path/path.dart' as p;

/// Extracts the disc/disk/CD number from a filename, or `null` when the name
/// carries no disc marker.
int? _discNumber(String filepath) {
  final match = RegExp(
    r'(?:disc|disk|cd)[\s\-_]*(\d+)',
    caseSensitive: false,
  ).firstMatch(p.basename(filepath));
  if (match == null) return null;
  return int.tryParse(match.group(1)!);
}

/// Orders a disc set so `(Disc 1)` precedes `(Disc 2)` precedes `(Disc 3)`.
///
/// The sort is stable: entries without a disc marker keep their original
/// relative order and are placed after the numbered discs.
List<String> orderDiscFiles(List<String> discFiles) {
  final indexed = discFiles.asMap().entries.toList();
  indexed.sort((a, b) {
    final na = _discNumber(a.value) ?? 1 << 30;
    final nb = _discNumber(b.value) ?? 1 << 30;
    if (na != nb) return na.compareTo(nb);
    return a.key.compareTo(b.key);
  });
  return indexed.map((e) => e.value).toList();
}

String generateM3u({
  required List<String> discFiles,
  required String outputPath,
  bool relative = true,
}) {
  if (discFiles.isEmpty) {
    throw ArgumentError('No disc files provided for M3U playlist.');
  }

  for (final f in discFiles) {
    if (!File(f).existsSync()) {
      throw FileSystemException('Disc file not found: $f', f);
    }
  }

  // Preserve every disc in the set, ordered by disc number.
  final orderedDiscs = orderDiscFiles(discFiles);

  final targetDir = Directory(outputPath).existsSync() ||
          !outputPath.toLowerCase().endsWith('.m3u')
      ? outputPath
      : p.dirname(outputPath);

  Directory(targetDir).createSync(recursive: true);

  final String m3uFilePath;
  if (outputPath.toLowerCase().endsWith('.m3u')) {
    m3uFilePath = outputPath;
  } else {
    final firstDiscName = p.basename(orderedDiscs.first);
    final cleanName = firstDiscName.replaceAll(
      RegExp(r'\s*\((?:Disc|cd|disk)\s*\d+\)', caseSensitive: false),
      '',
    );
    final idx = cleanName.lastIndexOf('.');
    final baseStem = idx != -1 ? cleanName.substring(0, idx) : cleanName;
    m3uFilePath = p.join(targetDir, '$baseStem.m3u');
  }

  final m3uDir = p.dirname(p.canonicalize(m3uFilePath));
  final buffer = StringBuffer();

  for (final discPath in orderedDiscs) {
    // The filename is written exactly as stored on disk: never lowercased,
    // so case-sensitive filesystems (Linux, SteamOS, Android) keep resolving.
    if (relative) {
      final relPath = p.relative(p.canonicalize(discPath), from: m3uDir);
      buffer.writeln(relPath);
    } else {
      buffer.writeln(p.canonicalize(discPath));
    }
  }

  File(m3uFilePath).writeAsStringSync(buffer.toString());
  return m3uFilePath;
}
