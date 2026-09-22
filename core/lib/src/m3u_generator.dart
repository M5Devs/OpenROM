// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:io';
import 'package:path/path.dart' as p;

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

  final targetDir = Directory(outputPath).existsSync() || !outputPath.toLowerCase().endsWith('.m3u')
      ? outputPath
      : p.dirname(outputPath);

  Directory(targetDir).createSync(recursive: true);

  final String m3uFilePath;
  if (outputPath.toLowerCase().endsWith('.m3u')) {
    m3uFilePath = outputPath;
  } else {
    final firstDiscName = p.basename(discFiles.first);
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

  for (final discPath in discFiles) {
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
