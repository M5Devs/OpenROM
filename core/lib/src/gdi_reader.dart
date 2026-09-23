// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;

class GdiTrack {
  final int number;
  final int lba;
  final int trackType;
  final int sectorSize;
  final String filename;
  final int filesize;

  GdiTrack({
    required this.number,
    required this.lba,
    required this.trackType,
    required this.sectorSize,
    required this.filename,
    required this.filesize,
  });

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'lba': lba,
      'type': trackType == 4 ? 'Data' : 'Audio',
      'sector_size': sectorSize,
      'filename': p.basename(filename),
      'filesize': filesize,
    };
  }
}

List<GdiTrack> parseGdi(String gdiPath) {
  final file = File(gdiPath);
  if (!file.existsSync()) {
    throw FileSystemException('GDI file not found: $gdiPath', gdiPath);
  }

  final gdiDir = p.dirname(p.canonicalize(gdiPath));
  final tracks = <GdiTrack>[];

  final lines = file.readAsLinesSync().where((l) => l.trim().isNotEmpty).toList();
  if (lines.isEmpty) return tracks;

  for (final line in lines.skip(1)) {
    final parts = line.trim().split(RegExp(r'\s+'));
    if (parts.length < 5) continue;
    try {
      final num = int.parse(parts[0]);
      final lba = int.parse(parts[1]);
      final ttype = int.parse(parts[2]);
      final sectorSize = int.parse(parts[3]);
      var filename = parts[4];
      if ((filename.startsWith('"') && filename.endsWith('"')) ||
          (filename.startsWith("'") && filename.endsWith("'"))) {
        filename = filename.substring(1, filename.length - 1);
      }
      final filepath = p.join(gdiDir, filename);
      final filesize = File(filepath).existsSync() ? File(filepath).lengthSync() : 0;

      tracks.add(GdiTrack(
        number: num,
        lba: lba,
        trackType: ttype,
        sectorSize: sectorSize,
        filename: filepath,
        filesize: filesize,
      ));
    } catch (_) {}
  }

  return tracks;
}

Uint8List extractIpbinFromGdi(String gdiPath) {
  final tracks = parseGdi(gdiPath);

  final dataTracks = tracks.where((t) => t.trackType == 4).toList();
  if (dataTracks.isEmpty) {
    throw FormatException('No data tracks found in GDI.');
  }

  var hdTracks = dataTracks.where((t) => t.lba >= 45000).toList();
  if (hdTracks.isEmpty) {
    hdTracks = dataTracks;
  }

  final track = hdTracks.first;
  final trackFile = File(track.filename);
  if (!trackFile.existsSync()) {
    throw FileSystemException('Track file not found: ${track.filename}', track.filename);
  }

  final raf = trackFile.openSync(mode: FileMode.read);
  try {
    if (track.sectorSize == 2352) {
      final sector = raf.readSync(2352);
      if (sector.length < 2352) {
        throw FormatException('Track file too small to read sector.');
      }
      return Uint8List.fromList(sector.sublist(16, 16 + 2048));
    } else {
      final data = raf.readSync(2048);
      if (data.length < 2048) {
        throw FormatException('Track file too small to read 2048 bytes.');
      }
      return Uint8List.fromList(data);
    }
  } finally {
    raf.closeSync();
  }
}
