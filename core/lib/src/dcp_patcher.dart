// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

import 'config.dart' as config;
import 'logger.dart' as logger;

class DcpPatcher {
  final void Function(String msg)? onLog;
  final void Function(double pct)? onProgress;

  DcpPatcher({this.onLog, this.onProgress});

  void _log(String msg) {
    logger.log(msg);
    if (onLog != null) {
      try {
        onLog!(msg);
      } catch (_) {}
    }
  }

  void _updateProgress(double pct) {
    if (onProgress != null) {
      try {
        onProgress!(pct);
      } catch (_) {}
    }
  }

  Map<String, dynamic> apply({
    required String dcpPath,
    required String discDir,
    required String outputDir,
    bool ignoreChecksum = false,
  }) {
    if (!File(dcpPath).existsSync()) {
      return {'success': false, 'error': 'DCP file not found: $dcpPath'};
    }
    if (!Directory(discDir).existsSync()) {
      return {'success': false, 'error': 'Disc directory not found: $discDir'};
    }

    final sourcePath = p.normalize(p.canonicalize(discDir));
    final requestedOutputPath = p.normalize(p.canonicalize(outputDir));
    if (requestedOutputPath == sourcePath ||
        requestedOutputPath.startsWith('$sourcePath${p.separator}')) {
      return {
        'success': false,
        'error': 'Output directory must be outside the source disc directory.',
      };
    }

    // Patch a sibling staging directory first so the requested output remains
    // untouched if archive decoding or patching fails halfway through.
    final outputPath = p.normalize(p.absolute(outputDir));
    final stagingDir = Directory(
      '${outputPath}.openrom-staging-${DateTime.now().microsecondsSinceEpoch}',
    );
    try {
      stagingDir.createSync(recursive: true);
    } catch (e) {
      return {
        'success': false,
        'error': 'Could not create staging directory: $e',
      };
    }

    try {
      _log('[DCP] Copying source disc to output directory...');
      _copyDisc(discDir, stagingDir.path);
      _updateProgress(10.0);
    } catch (e) {
      try {
        stagingDir.deleteSync(recursive: true);
      } catch (_) {}
      return {'success': false, 'error': 'Could not stage source disc: $e'};
    }

    final result = <String, dynamic>{
      'success': false,
      'files_patched': 0,
      'xdelta_applied': 0,
      'ipbin_replaced': false,
      'error': null,
    };

    try {
      final bytes = File(dcpPath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      final total = archive.length == 0 ? 1 : archive.length;
      _log('[DCP] Archive contains $total entries.');

      final basePath = p.normalize(p.canonicalize(stagingDir.path));
      final xdeltaEntries = <ArchiveFile>[];

      for (int i = 0; i < archive.length; i++) {
        final pct = 10.0 + (i / total) * 80.0;
        _updateProgress(pct);

        final file = archive[i];
        final name = file.name;
        final destPath = p.normalize(p.join(basePath, name));

        if (!destPath.startsWith(basePath + p.separator) &&
            destPath != basePath) {
          throw FormatException(
            'Malicious archive entry detected (Path Traversal): $name',
          );
        }

        if (name.toLowerCase() == 'bootsector/ip.bin') {
          final ipbinData = file.content as List<int>;
          File(p.join(stagingDir.path, 'IP.BIN')).writeAsBytesSync(ipbinData);
          result['ipbin_replaced'] = true;
          _log('[DCP] Replaced IP.BIN from patch.');
          continue;
        }

        if (name.startsWith('xdelta/') || name.startsWith('xdelta\\')) {
          if (file.isFile) {
            xdeltaEntries.add(file);
          }
          continue;
        }

        if (!file.isFile) continue;

        File(destPath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(file.content as List<int>);
        result['files_patched'] = (result['files_patched'] as int) + 1;
        _log('[DCP] Replaced: $name');
      }

      if (xdeltaEntries.isNotEmpty) {
        final xdeltaApplied = _applyXdeltaPatches(
          xdeltaEntries,
          stagingDir.path,
          ignoreChecksum,
        );
        result['xdelta_applied'] = xdeltaApplied;
        result['files_patched'] =
            (result['files_patched'] as int) + xdeltaApplied;
      }

      _updateProgress(100.0);
      _commitStaging(stagingDir, outputPath);
      result['success'] = true;
      _log(
        '[DCP] Done. Files patched: ${result["files_patched"]}, '
        'xdelta: ${result["xdelta_applied"]}, '
        'IP.BIN replaced: ${result["ipbin_replaced"]}',
      );
      return result;
    } catch (e) {
      result['error'] = e.toString();
      _log('[DCP ERROR] $e');
      return result;
    } finally {
      if (stagingDir.existsSync()) {
        try {
          stagingDir.deleteSync(recursive: true);
        } catch (_) {}
      }
    }
  }

  int _applyXdeltaPatches(
    List<ArchiveFile> xdeltaEntries,
    String outputDir,
    bool ignoreChecksum,
  ) {
    final xdelta3 = config.getToolPath('xdelta3');
    int applied = 0;

    final tempDir = Directory.systemTemp.createTempSync('openrom_dcp_');
    try {
      final basePath = p.normalize(p.canonicalize(outputDir));

      for (final entry in xdeltaEntries) {
        final archivePrefix = entry.name.startsWith('xdelta\\')
            ? 'xdelta\\'
            : 'xdelta/';
        final relativePatchName = entry.name.substring(archivePrefix.length);
        String targetName = relativePatchName.replaceAll('\\', '/');

        for (final ext in ['.xdelta3', '.xdelta', '.xd', '.vcdiff']) {
          if (targetName.toLowerCase().endsWith(ext)) {
            targetName = targetName.substring(
              0,
              targetName.length - ext.length,
            );
            break;
          }
        }

        final destPath = p.normalize(p.join(basePath, targetName));
        if (!destPath.startsWith(basePath + p.separator) &&
            destPath != basePath) {
          throw FormatException(
            'Malicious archive entry detected (Path Traversal): ${entry.name}',
          );
        }

        final patchTmp = p.join(tempDir.path, p.basename(relativePatchName));
        final sourcePath = destPath;
        final outputPath = '$destPath.patched';

        if (!File(sourcePath).existsSync()) {
          _log('[DCP WARN] xdelta source not found: $targetName — skipping');
          continue;
        }

        File(patchTmp).writeAsBytesSync(entry.content as List<int>);

        final args = [xdelta3, '-d'];
        if (ignoreChecksum) {
          args.add('-n');
        }
        args.addAll(['-s', sourcePath, patchTmp, outputPath]);

        try {
          final res = Process.runSync(args.removeAt(0), args);
          if (res.exitCode == 0) {
            File(outputPath).renameSync(sourcePath);
            applied++;
            _log('[DCP xdelta] Patched: $targetName');
          } else {
            final err = res.stderr.toString().trim();
            _log('[DCP xdelta ERROR] $targetName: $err');
          }
        } catch (_) {
          _log('[DCP ERROR] xdelta3 binary execution failed.');
          break;
        }
      }
    } finally {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    }

    return applied;
  }

  void _copyDisc(String srcDir, String dstDir) {
    final dir = Directory(srcDir);
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is File) {
        final rel = p.relative(entity.path, from: srcDir);
        final dstPath = p.join(dstDir, rel);
        File(dstPath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(entity.readAsBytesSync());
      }
    }
  }

  void _commitStaging(Directory stagingDir, String outputDir) {
    final target = Directory(outputDir);
    target.createSync(recursive: true);
    for (final entity in stagingDir.listSync(recursive: true)) {
      if (entity is! File) continue;
      final rel = p.relative(entity.path, from: stagingDir.path);
      final dest = File(p.join(outputDir, rel));
      dest
        ..createSync(recursive: true)
        ..writeAsBytesSync(entity.readAsBytesSync());
    }
  }
}
