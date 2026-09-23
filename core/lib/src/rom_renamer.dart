// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:xml/xml_events.dart';
import 'config.dart' as config;

final Uint32List _crc32Table = () {
  final table = Uint32List(256);
  for (int i = 0; i < 256; i++) {
    int c = i;
    for (int k = 0; k < 8; k++) {
      if ((c & 1) != 0) {
        c = 0xEDB88320 ^ (c >> 1);
      } else {
        c = c >> 1;
      }
    }
    table[i] = c;
  }
  return table;
}();

int getCrc32(List<int> bytes, [int crc = 0]) {
  int c = crc ^ 0xFFFFFFFF;
  for (int i = 0; i < bytes.length; i++) {
    c = _crc32Table[(c ^ bytes[i]) & 0xFF] ^ (c >> 8);
  }
  return c ^ 0xFFFFFFFF;
}

String getDatsDir() {
  final datsDir = p.join(config.getDirectoryConfig(), 'dats');
  Directory(datsDir).createSync(recursive: true);
  return datsDir;
}

Map<String, dynamic> _readDatHeaderSync(String datPath) {
  String datName = '';
  String datUrl = '';
  int gameCount = 0;
  bool headerFound = false;

  final content = File(datPath).readAsStringSync();
  final events = parseEvents(content);

  String? currentTag;
  for (final event in events) {
    if (event is XmlStartElementEvent) {
      currentTag = event.name;
      if (event.name == 'game') {
        gameCount++;
      }
    } else if (event is XmlTextEvent) {
      if (currentTag == 'name' && datName.isEmpty) {
        datName = event.value.trim();
      } else if (currentTag == 'url' && datUrl.isEmpty) {
        datUrl = event.value.trim();
      }
    } else if (event is XmlEndElementEvent) {
      if (event.name == 'header') {
        headerFound = true;
      }
      currentTag = null;
    }
  }

  if (!headerFound && datName.isEmpty) {
    datName = p.basename(datPath);
  }

  final String source;
  if (datUrl.toLowerCase().contains('no-intro')) {
    source = 'No-Intro';
  } else if (datUrl.toLowerCase().contains('redump')) {
    source = 'Redump';
  } else {
    source = 'Unknown';
  }

  return {
    'name': datName,
    'source': source,
    'game_count': gameCount,
    'url': datUrl,
  };
}

Map<String, dynamic> importDat(String datPath) {
  if (!File(datPath).existsSync()) {
    throw ArgumentError('File not found: $datPath');
  }

  final headerInfo = _readDatHeaderSync(datPath);
  final datName = headerInfo['name'] as String;
  final datUrl = headerInfo['url'] as String;
  final source = headerInfo['source'] as String;
  final gameCount = headerInfo['game_count'] as int;

  final safeName = datName.replaceAll(RegExp(r'[^a-zA-Z0-9\ ._\-\(\)]'), '_');
  final storedPath = p.join(getDatsDir(), '$safeName.dat');
  File(datPath).copySync(storedPath);

  return {
    'name': datName,
    'source': source,
    'system': datName,
    'game_count': gameCount,
    'stored_path': storedPath,
    'url': datUrl,
  };
}

List<Map<String, dynamic>> listDats() {
  final datsDir = getDatsDir();
  final dir = Directory(datsDir);
  final result = <Map<String, dynamic>>[];
  if (!dir.existsSync()) return result;

  final entries = dir.listSync()..sort((a, b) => a.path.compareTo(b.path));
  for (final entry in entries) {
    if (entry is File && entry.path.endsWith('.dat')) {
      try {
        final info = _readDatHeaderSync(entry.path);
        info['stored_path'] = entry.path;
        result.add(info);
      } catch (_) {}
    }
  }
  return result;
}

void removeDat(String storedPath) {
  final file = File(storedPath);
  if (file.existsSync()) {
    file.deleteSync();
  }
}

String calcCrc32(String filepath, {void Function(double pct)? onProgress}) {
  final file = File(filepath);
  final fileSize = file.lengthSync();
  int bytesRead = 0;
  const chunkSize = 1024 * 1024; // 1MB

  final raf = file.openSync(mode: FileMode.read);
  var crc = 0;

  try {
    while (true) {
      final chunk = raf.readSync(chunkSize);
      if (chunk.isEmpty) break;
      crc = getCrc32(chunk, crc);
      bytesRead += chunk.length;
      if (onProgress != null && fileSize > 0) {
        onProgress(bytesRead / fileSize * 100.0);
      }
    }
  } finally {
    raf.closeSync();
  }

  final hex = (crc & 0xFFFFFFFF).toRadixString(16).toLowerCase().padLeft(8, '0');
  return hex;
}

Map<String, Map<String, dynamic>> loadDatIndex(String datPath) {
  final index = <String, Map<String, dynamic>>{};
  final content = File(datPath).readAsStringSync();
  final events = parseEvents(content);

  String currentGameName = '';
  String currentDesc = '';
  String? currentTextTag;

  for (final event in events) {
    if (event is XmlStartElementEvent) {
      if (event.name == 'game') {
        currentGameName = '';
        currentDesc = '';
        for (final attr in event.attributes) {
          if (attr.name == 'name') {
            currentGameName = attr.value;
          }
        }
      } else if (event.name == 'description') {
        currentTextTag = 'description';
      } else if (event.name == 'rom') {
        String crc = '';
        String romName = '';
        int size = 0;
        String md5 = '';
        String sha1 = '';

        for (final attr in event.attributes) {
          if (attr.name == 'crc') {
            crc = attr.value.trim().toLowerCase().padLeft(8, '0');
          } else if (attr.name == 'name') {
            romName = attr.value;
          } else if (attr.name == 'size') {
            size = int.tryParse(attr.value) ?? 0;
          } else if (attr.name == 'md5') {
            md5 = attr.value.trim().toLowerCase();
          } else if (attr.name == 'sha1') {
            sha1 = attr.value.trim().toLowerCase();
          }
        }

        if (crc.isNotEmpty) {
          index[crc] = {
            'name': currentGameName,
            'description': currentDesc.isNotEmpty ? currentDesc : currentGameName,
            'rom_name': romName,
            'size': size,
            'md5': md5,
            'sha1': sha1,
          };
        }
      }
    } else if (event is XmlTextEvent) {
      if (currentTextTag == 'description') {
        currentDesc = event.value.trim();
      }
    } else if (event is XmlEndElementEvent) {
      if (event.name == 'description') {
        currentTextTag = null;
      }
    }
  }

  return index;
}

class RomScanResult {
  final String filepath;
  final String filename;
  String crc32;
  bool matched;
  String canonicalName;
  String romName;
  String datSource;
  String error;

  RomScanResult({
    required this.filepath,
    required this.filename,
    this.crc32 = '',
    this.matched = false,
    this.canonicalName = '',
    this.romName = '',
    this.datSource = '',
    this.error = '',
  });

  String get suggestedFilename {
    if (!matched || romName.isEmpty) return filename;
    return romName;
  }
}

List<RomScanResult> scanFolder(
  String folder,
  List<String> datPaths, {
  void Function(String filename, double percent)? onProgress,
  void Function(RomScanResult result)? onResult,
}) {
  final dir = Directory(folder);
  if (!dir.existsSync()) {
    throw ArgumentError('Folder not found: $folder');
  }

  final datIndexes = <Map<String, dynamic>>[];
  final skippedDats = <Map<String, String>>[];

  for (final dp in datPaths) {
    try {
      final header = _readDatHeaderSync(dp);
      final index = loadDatIndex(dp);
      datIndexes.add({
        'index': index,
        'name': header['name'],
        'source': header['source'],
      });
    } catch (e) {
      skippedDats.add({'name': p.basename(dp), 'reason': e.toString()});
    }
  }

  for (final sk in skippedDats) {
    if (onProgress != null) {
      onProgress('[WARN] Skipped unreadable DAT: ${sk['name']} (${sk['reason']})', 0.0);
    }
  }

  const extensions = {
    '.smc', '.sfc', '.nes', '.gba', '.gb', '.gbc',
    '.n64', '.z64', '.v64', '.ndd',
    '.md', '.gen', '.sms', '.gg', '.32x',
    '.pce', '.iso', '.bin', '.img', '.chd',
    '.ws', '.wsc', '.ngp', '.ngc',
    '.lnx', '.vb', '.vec', '.a26', '.a52', '.j64',
  };

  final entries = dir.listSync();
  final files = <String>[];
  for (final entry in entries) {
    if (entry is File) {
      final fname = p.basename(entry.path);
      final ext = p.extension(fname).toLowerCase();
      if (extensions.contains(ext)) {
        files.add(fname);
      }
    }
  }
  files.sort();

  final results = <RomScanResult>[];
  for (final fname in files) {
    final fpath = p.join(folder, fname);
    final result = RomScanResult(filepath: fpath, filename: fname);

    try {
      result.crc32 = calcCrc32(fpath, onProgress: (pct) {
        if (onProgress != null) onProgress(fname, pct);
      });

      for (final datEntry in datIndexes) {
        final index = datEntry['index'] as Map<String, Map<String, dynamic>>;
        final datSource = datEntry['source'] as String;

        if (index.containsKey(result.crc32)) {
          final item = index[result.crc32]!;
          result.matched = true;
          result.canonicalName = item['name'] as String;
          result.romName = item['rom_name'] as String;
          result.datSource = datSource;
          break;
        }
      }
    } catch (e) {
      result.error = e.toString();
    }

    results.add(result);
    if (onResult != null) {
      onResult(result);
    }
  }

  return results;
}

class RenameResult {
  final String originalPath;
  final String newPath;
  bool success;
  String error;

  RenameResult({
    required this.originalPath,
    required this.newPath,
    required this.success,
    this.error = '',
  });
}

List<RenameResult> renameRoms(
  List<RomScanResult> results, {
  bool dryRun = true,
  void Function(RenameResult r)? onRenamed,
}) {
  final renameResults = <RenameResult>[];

  for (final scan in results) {
    if (!scan.matched) continue;
    if (scan.filename == scan.suggestedFilename) continue;

    final folder = p.dirname(scan.filepath);
    final newPath = p.join(folder, scan.suggestedFilename);
    final r = RenameResult(
      originalPath: scan.filepath,
      newPath: newPath,
      success: false,
    );

    try {
      if (!dryRun) {
        if (File(newPath).existsSync() &&
            p.canonicalize(newPath) != p.canonicalize(scan.filepath)) {
          r.error = 'Target already exists: ${scan.suggestedFilename}';
        } else {
          File(scan.filepath).renameSync(newPath);
          r.success = true;
        }
      } else {
        r.success = true;
      }
    } catch (e) {
      r.error = e.toString();
    }

    renameResults.add(r);
    if (onRenamed != null) {
      onRenamed(r);
    }
  }

  return renameResults;
}
