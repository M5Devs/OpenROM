// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'config.dart' as config;
import 'logger.dart' as logger;

class _PendingEntry {
  final String archivePath;
  final File file;
    _PendingEntry({required this.archivePath, required this.file});
}

/// Universal Dreamcast Patcher (DCP) builder.
/// Compares two extracted disc directory trees (original and modified)
/// and creates a .dcp (ZIP) archive compatible with UDP v2.1.7.
class DcpBuilder {
  final Directory originalDir;
  final Directory modifiedDir;
  final File outputFile;
  final bool useXdelta;
  final void Function(String msg)? onLog;
  final void Function(double pct)? onProgress;

  DcpBuilder({
    required this.originalDir,
    required this.modifiedDir,
    required this.outputFile,
    this.useXdelta = true,
    this.onLog,
    this.onProgress,
  });

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

  Future<void> build() async {
    if (!originalDir.existsSync()) {
      throw FormatException('Original disc directory not found: ${originalDir.path}');
    }
    if (!modifiedDir.existsSync()) {
      throw FormatException('Modified disc directory not found: ${modifiedDir.path}');
    }

    _log('[DCP Builder] Scanning directory differences...');
    _updateProgress(5.0);

    final tempDir = Directory.systemTemp.createTempSync('openrom_dcp_build_');
    try {
      final pendingEntries = <_PendingEntry>[];
      final modFiles = _listAllFiles(modifiedDir);
      final totalFiles = modFiles.isEmpty ? 1 : modFiles.length;

      int diffed = 0;
      int added = 0;
      bool ipbinAdded = false;

      final xdelta3Path = config.getToolPath('xdelta3');
      final bool canUseXdelta = useXdelta && File(xdelta3Path).existsSync();

      if (useXdelta && !canUseXdelta) {
        _log('[DCP Builder WARN] xdelta3 tool not found at "$xdelta3Path". Falling back to verbatim files.');
      }

      for (int i = 0; i < modFiles.length; i++) {
        final pct = 5.0 + ((i + 1) / totalFiles) * 80.0;
        _updateProgress(pct);

        final modFile = modFiles[i];
        final relPath = p.relative(modFile.path, from: modifiedDir.path).replaceAll('\\', '/');
        final normRelLower = relPath.toLowerCase();

        // Bootsector / IP.BIN handling
        if (normRelLower == 'bootsector/ip.bin' || normRelLower == 'ip.bin') {
          final origIpBinPath1 = p.join(originalDir.path, 'bootsector', 'IP.BIN');
          final origIpBinPath2 = p.join(originalDir.path, 'IP.BIN');
          File? origIpBin;
          if (File(origIpBinPath1).existsSync()) {
            origIpBin = File(origIpBinPath1);
          } else if (File(origIpBinPath2).existsSync()) {
            origIpBin = File(origIpBinPath2);
          }

          if (origIpBin == null || !_filesEqual(origIpBin, modFile)) {
            _log('[DCP Builder] Adding bootsector/IP.BIN');
            pendingEntries.add(_PendingEntry(
              archivePath: 'bootsector/IP.BIN',
              file: modFile,
            ));
            ipbinAdded = true;
          }
          continue;
        }

        if (normRelLower.startsWith('bootsector/')) {
          continue;
        }

        final origFile = File(p.join(originalDir.path, relPath.replaceAll('/', p.separator)));

        if (!origFile.existsSync()) {
          // New file added verbatim
          _log('[DCP Builder] Adding verbatim: $relPath');
          pendingEntries.add(_PendingEntry(
            archivePath: relPath,
            file: modFile,
          ));
          added++;
        } else {
          if (_filesEqual(origFile, modFile)) {
            // File unchanged
            continue;
          }

          // File changed
          if (canUseXdelta) {
            final patchTmpPath = p.join(tempDir.path, 'patch_$diffed.xd');
            final xdeltaRelPath = 'xdelta/$relPath.xdelta';

            _log('[DCP Builder] Encoding xdelta diff for $relPath...');
            final success = _encodeXdelta(
              xdelta3Path: xdelta3Path,
              origFile: origFile,
              modFile: modFile,
              outputTmpFile: File(patchTmpPath),
            );

            if (success && File(patchTmpPath).existsSync()) {
              pendingEntries.add(_PendingEntry(
                archivePath: xdeltaRelPath,
                file: File(patchTmpPath),
              ));
              diffed++;
            } else {
              _log('[DCP Builder WARN] xdelta encoding failed for $relPath. Including verbatim.');
              pendingEntries.add(_PendingEntry(
                archivePath: relPath,
                file: modFile,
              ));
              added++;
            }
          } else {
            _log('[DCP Builder] Adding changed file verbatim: $relPath');
            pendingEntries.add(_PendingEntry(
              archivePath: relPath,
              file: modFile,
            ));
            added++;
          }
        }
      }

      // Sort pending entries deterministically by archive path
      pendingEntries.sort((a, b) => a.archivePath.compareTo(b.archivePath));

      final archive = Archive();
      for (final entry in pendingEntries) {
        final data = entry.file.readAsBytesSync();
        archive.addFile(ArchiveFile(
          entry.archivePath,
          data.length,
          data,
        ));
      }

      _log('[DCP Builder] Writing DCP archive to ${outputFile.path}...');
      _updateProgress(90.0);

      outputFile.parent.createSync(recursive: true);
      final zipData = ZipEncoder().encode(archive);
      if (zipData == null) {
        throw FormatException('Failed to encode ZIP archive for DCP.');
      }
      outputFile.writeAsBytesSync(zipData);

      _updateProgress(100.0);
      _log('[DCP Builder] Complete. Added verbatim: $added, xdelta diffs: $diffed, IP.BIN included: $ipbinAdded');
    } finally {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  }

  bool _encodeXdelta({
    required String xdelta3Path,
    required File origFile,
    required File modFile,
    required File outputTmpFile,
  }) {
    try {
      final res = Process.runSync(xdelta3Path, [
        '-e',
        '-s',
        origFile.path,
        modFile.path,
        outputTmpFile.path,
      ]);
      return res.exitCode == 0;
    } catch (e) {
      _log('[DCP Builder ERROR] xdelta execution failed: $e');
      return false;
    }
  }

  List<File> _listAllFiles(Directory dir) {
    final files = <File>[];
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is File) {
        files.add(entity);
      }
    }
    return files;
  }

  bool _filesEqual(File a, File b) {
    if (a.lengthSync() != b.lengthSync()) return false;
    final hashA = sha256.convert(a.readAsBytesSync());
    final hashB = sha256.convert(b.readAsBytesSync());
    return hashA == hashB;
  }
}
