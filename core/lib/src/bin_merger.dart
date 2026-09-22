// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:io';
import 'package:path/path.dart' as p;

String _sectorsToMsf(int sectors) {
  final mm = sectors ~/ (75 * 60);
  final rem = sectors % (75 * 60);
  final ss = rem ~/ 75;
  final ff = rem % 75;
  return '${mm.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}:${ff.toString().padLeft(2, '0')}';
}

int _msfToSectors(String msf) {
  final parts = msf.split(':').map(int.parse).toList();
  return parts[0] * 60 * 75 + parts[1] * 75 + parts[2];
}

int _getSectorSize(String mode) {
  final modeUpper = mode.toUpperCase();
  if (modeUpper.contains('2048')) return 2048;
  if (modeUpper.contains('2336')) return 2336;
  return 2352;
}

class CueTrackIndex {
  final int number;
  final String msf;

  CueTrackIndex({required this.number, required this.msf});
}

class CueTrack {
  final int trackNumber;
  final String mode;
  final String? file;
  final String relFile;
  final List<CueTrackIndex> indexes;

  CueTrack({
    required this.trackNumber,
    required this.mode,
    required this.file,
    required this.relFile,
    required this.indexes,
  });
}

List<CueTrack> parseCue(String cuePath) {
  final cueDir = p.dirname(p.canonicalize(cuePath));
  final tracks = <CueTrack>[];

  String? currentFile;
  final fileRegex = RegExp('FILE\\s+["\']?([^"\']+)["\']?\\s+BINARY', caseSensitive: false);
  final trackRegex = RegExp('TRACK\\s+(\\d+)\\s+([^\\s]+)', caseSensitive: false);
  final indexRegex = RegExp('INDEX\\s+(\\d+)\\s+(\\d{2}:\\d{2}:\\d{2})', caseSensitive: false);

  final lines = File(cuePath).readAsLinesSync();
  for (final line in lines) {
    final lineStr = line.trim();
    final fm = fileRegex.firstMatch(lineStr);
    if (fm != null) {
      final relFile = fm.group(1)!;
      currentFile = p.join(cueDir, relFile);
      continue;
    }

    final tm = trackRegex.firstMatch(lineStr);
    if (tm != null) {
      final num = int.parse(tm.group(1)!);
      final mode = tm.group(2)!;
      tracks.add(CueTrack(
        trackNumber: num,
        mode: mode,
        file: currentFile,
        relFile: currentFile != null ? p.basename(currentFile) : '',
        indexes: [],
      ));
      continue;
    }

    final im = indexRegex.firstMatch(lineStr);
    if (im != null && tracks.isNotEmpty) {
      final idxNum = int.parse(im.group(1)!);
      final idxMsf = im.group(2)!;
      tracks.last.indexes.add(CueTrackIndex(number: idxNum, msf: idxMsf));
    }
  }

  return tracks;
}

class BinMergeResult {
  final String mergedBinPath;
  final String mergedCuePath;

  BinMergeResult(this.mergedBinPath, this.mergedCuePath);
}

BinMergeResult mergeBins(
  String cuePath, {
  String? outputDir,
  void Function(double pct)? onProgress,
}) {
  if (!File(cuePath).existsSync()) {
    throw FileSystemException('CUE file not found: $cuePath', cuePath);
  }

  final cueDir = p.dirname(p.canonicalize(cuePath));
  final targetDir = (outputDir != null && outputDir.isNotEmpty) ? outputDir : cueDir;
  Directory(targetDir).createSync(recursive: true);

  final tracks = parseCue(cuePath);
  if (tracks.isEmpty) {
    throw FormatException('No tracks found in CUE file: $cuePath');
  }

  for (final t in tracks) {
    final binFile = t.file;
    if (binFile == null || !File(binFile).existsSync()) {
      throw FileSystemException('Referenced BIN file not found: $binFile', binFile);
    }
  }

  final cueName = p.basename(cuePath);
  final idx = cueName.lastIndexOf('.');
  final baseStem = idx != -1 ? cueName.substring(0, idx) : cueName;

  final mergedBinName = '${baseStem}_merged.bin';
  final mergedCueName = '${baseStem}_merged.cue';

  final mergedBinPath = p.join(targetDir, mergedBinName);
  final mergedCuePath = p.join(targetDir, mergedCueName);

  int totalBytes = 0;
  for (final t in tracks) {
    totalBytes += File(t.file!).lengthSync();
  }
  int bytesWritten = 0;

  int accumulatedSectors = 0;
  final newCueTracks = <Map<String, dynamic>>[];

  final outBinFile = File(mergedBinPath);
  final outSink = outBinFile.openSync(mode: FileMode.write);

  try {
    for (final t in tracks) {
      final binPath = t.file!;
      final mode = t.mode;
      final secSize = _getSectorSize(mode);

      final fileSize = File(binPath).lengthSync();
      final sectorsInFile = fileSize ~/ secSize;

      final parsedIndexes = t.indexes;

      List<CueTrackIndex> computedIndexes;
      if (parsedIndexes.isNotEmpty) {
        CueTrackIndex? idx01Entry;
        for (final item in parsedIndexes) {
          if (item.number == 1) {
            idx01Entry = item;
            break;
          }
        }
        final idx01Offset = idx01Entry != null ? _msfToSectors(idx01Entry.msf) : 0;

        computedIndexes = [];
        for (final idxItem in parsedIndexes) {
          final idxOffset = _msfToSectors(idxItem.msf);
          final idxSectors = accumulatedSectors + (idxOffset - idx01Offset);
          computedIndexes.add(CueTrackIndex(
            number: idxItem.number,
            msf: _sectorsToMsf(idxSectors),
          ));
        }
      } else {
        computedIndexes = [
          CueTrackIndex(number: 1, msf: _sectorsToMsf(accumulatedSectors)),
        ];
      }

      newCueTracks.add({
        'trackNumber': t.trackNumber,
        'mode': mode,
        'indexes': computedIndexes,
      });

      accumulatedSectors += sectorsInFile;

      final inRaf = File(binPath).openSync(mode: FileMode.read);
      const chunkSize = 1024 * 1024;
      while (true) {
        final chunk = inRaf.readSync(chunkSize);
        if (chunk.isEmpty) break;
        outSink.writeFromSync(chunk);
        bytesWritten += chunk.length;
        if (onProgress != null && totalBytes > 0) {
          final pct = (bytesWritten / totalBytes * 100.0).clamp(0.0, 100.0);
          onProgress(pct);
        }
      }
      inRaf.closeSync();
    }
  } finally {
    outSink.closeSync();
  }

  if (onProgress != null) {
    onProgress(100.0);
  }

  final cueBuffer = StringBuffer();
  cueBuffer.writeln('FILE "$mergedBinName" BINARY');
  for (final ct in newCueTracks) {
    final trackNum = (ct['trackNumber'] as int).toString().padLeft(2, '0');
    final mode = ct['mode'] as String;
    cueBuffer.writeln('  TRACK $trackNum $mode');
    final indexes = ct['indexes'] as List<CueTrackIndex>;
    for (final idxItem in indexes) {
      final idxNum = idxItem.number.toString().padLeft(2, '0');
      cueBuffer.writeln('    INDEX $idxNum ${idxItem.msf}');
    }
  }

  File(mergedCuePath).writeAsStringSync(cueBuffer.toString());

  return BinMergeResult(mergedBinPath, mergedCuePath);
}
