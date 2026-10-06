// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:io';
import 'package:path/path.dart' as p;

class OneGOneRFileResult {
  final String originalPath;
  final String filename;
  final String cleanTitle;
  final bool isWinner;
  final String? destinationPath;
  final String reason;

  OneGOneRFileResult({
    required this.originalPath,
    required this.filename,
    required this.cleanTitle,
    required this.isWinner,
    this.destinationPath,
    required this.reason,
  });

  Map<String, dynamic> toJson() => {
        'original_path': originalPath,
        'filename': filename,
        'clean_title': cleanTitle,
        'is_winner': isWinner,
        'destination_path': destinationPath,
        'reason': reason,
      };
}

class OneGOneRSummary {
  final int totalFiles;
  final int keptCount;
  final int movedCount;
  final List<OneGOneRFileResult> results;

  OneGOneRSummary({
    required this.totalFiles,
    required this.keptCount,
    required this.movedCount,
    required this.results,
  });

  Map<String, dynamic> toJson() => {
        'total_files': totalFiles,
        'kept_count': keptCount,
        'moved_count': movedCount,
        'results': results.map((r) => r.toJson()).toList(),
      };
}

String extractCleanTitle(String filename) {
  // Remove file extension
  String title = p.basenameWithoutExtension(filename);
  // Remove parenthesized ( ... ) and bracketed [ ... ] tags
  title = title.replaceAll(RegExp(r'[\(\[][^\)\]]*[\)\]]'), '');
  // Trim extra spaces
  return title.trim();
}

int _getRegionRank(String filename, List<String> regionPriority) {
  final nameLower = filename.toLowerCase();

  // Extract text inside parentheses and brackets
  final tags = RegExp(
    r'[\(\[][^\)\]]*[\)\]]',
  ).allMatches(nameLower).map((m) => m.group(0)!).toList();

  for (int i = 0; i < regionPriority.length; i++) {
    final region = regionPriority[i].trim().toLowerCase();
    if (region.isEmpty) continue;

    for (final tag in tags) {
      if (_tagMatchesRegion(tag, region)) {
        return i;
      }
    }
  }
  return 9999;
}

bool _tagMatchesRegion(String tagContent, String region) {
  if (region == 'usa' || region == 'us') {
    return tagContent.contains('usa') ||
        tagContent.contains('us,') ||
        tagContent.contains('us)') ||
        tagContent.contains('america');
  }
  if (region == 'europe' || region == 'eur' || region == 'eu') {
    return tagContent.contains('europe') ||
        tagContent.contains('eur') ||
        tagContent.contains('eu,') ||
        tagContent.contains('eu)');
  }
  if (region == 'japan' || region == 'jpn' || region == 'jp') {
    return tagContent.contains('japan') ||
        tagContent.contains('jpn') ||
        tagContent.contains('jp,') ||
        tagContent.contains('jp)');
  }
  if (region == 'world') {
    return tagContent.contains('world');
  }
  return tagContent.contains(region);
}

int _getRevisionLevel(String filename) {
  final nameLower = filename.toLowerCase();

  // Match Rev X, Revision X
  final revMatch = RegExp(
    r'\b(?:rev|revision)[\s\._]*([0-9a-z]+)\b',
  ).firstMatch(nameLower);
  if (revMatch != null) {
    final val = revMatch.group(1)!;
    final parsed = int.tryParse(val);
    if (parsed != null) return parsed;
    if (val == 'a') return 1;
    if (val == 'b') return 2;
    if (val == 'c') return 3;
    return 1;
  }

  // Match v1.1, v1.2, v2.0
  final vMatch = RegExp(r'\bv(\d+)(?:\.(\d+))?\b').firstMatch(nameLower);
  if (vMatch != null) {
    final major = int.tryParse(vMatch.group(1) ?? '1') ?? 1;
    final minor = int.tryParse(vMatch.group(2) ?? '0') ?? 0;
    return major * 10 + minor;
  }

  return 0;
}

int _getDumpScore(String filename) {
  int score = 0;
  if (filename.contains('[!]')) score += 10;
  if (filename.contains('[b') || filename.contains('[h')) score -= 10;
  return score;
}

OneGOneRSummary filter1G1R({
  required String folderPath,
  List<String> regionPriority = const ['USA', 'Europe', 'Japan'],
  bool dryRun = false,
  bool moveDuplicates = true,
}) {
  final dir = Directory(folderPath);
  if (!dir.existsSync()) {
    throw FileSystemException('Folder does not exist', folderPath);
  }

  final files = dir
      .listSync(recursive: false)
      .whereType<File>()
      .where((f) => !p.basename(f.path).startsWith('.'))
      .toList();

  final Map<String, List<File>> clusters = {};

  for (final file in files) {
    final fname = p.basename(file.path);
    final clean = extractCleanTitle(fname);
    if (clean.isEmpty) continue;
    clusters.putIfAbsent(clean, () => []).add(file);
  }

  final results = <OneGOneRFileResult>[];
  int keptCount = 0;
  int movedCount = 0;

  final dupDir = Directory(p.join(folderPath, '_duplicates'));

  clusters.forEach((cleanTitle, fileList) {
    if (fileList.isEmpty) return;

    // Sort candidates so the top candidate is index 0
    fileList.sort((a, b) {
      final fnameA = p.basename(a.path);
      final fnameB = p.basename(b.path);

      // 1. Region rank (lower index is better)
      final rankA = _getRegionRank(fnameA, regionPriority);
      final rankB = _getRegionRank(fnameB, regionPriority);
      if (rankA != rankB) return rankA.compareTo(rankB);

      // 2. Revision level (higher is better)
      final revA = _getRevisionLevel(fnameA);
      final revB = _getRevisionLevel(fnameB);
      if (revA != revB) return revB.compareTo(revA);

      // 3. Dump score
      final dumpA = _getDumpScore(fnameA);
      final dumpB = _getDumpScore(fnameB);
      if (dumpA != dumpB) return dumpB.compareTo(dumpA);

      // Tie breaker: alphabetical
      return fnameA.compareTo(fnameB);
    });

    final winner = fileList.first;
    final winnerName = p.basename(winner.path);

    results.add(
      OneGOneRFileResult(
        originalPath: winner.path,
        filename: winnerName,
        cleanTitle: cleanTitle,
        isWinner: true,
        reason: 'Preferred regional/revision version',
      ),
    );
    keptCount++;

    for (int i = 1; i < fileList.length; i++) {
      final dup = fileList[i];
      final dupName = p.basename(dup.path);
      final destPath = p.join(dupDir.path, dupName);

      if (!dryRun && moveDuplicates) {
        if (!dupDir.existsSync()) {
          dupDir.createSync(recursive: true);
        }
        dup.renameSync(destPath);
      }

      results.add(
        OneGOneRFileResult(
          originalPath: dup.path,
          filename: dupName,
          cleanTitle: cleanTitle,
          isWinner: false,
          destinationPath: destPath,
          reason: 'Duplicate of $winnerName',
        ),
      );
      movedCount++;
    }
  });

  return OneGOneRSummary(
    totalFiles: files.length,
    keptCount: keptCount,
    movedCount: movedCount,
    results: results,
  );
}
