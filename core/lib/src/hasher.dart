// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';

/// Default read buffer. Large enough to keep syscall overhead low, small enough
/// that a multi-gigabyte ISO never has more than this much in memory.
const int kHashChunkSize = 1024 * 1024;

/// Every checksum produced by [RomHasher] in a single streaming pass.
class HashResult {
  /// CRC-32 as 8 uppercase hex characters (e.g. `CBF43926`).
  final String crc32;

  /// MD5 as 32 lowercase hex characters.
  final String md5;

  /// SHA-1 as 40 lowercase hex characters.
  final String sha1;

  /// SHA-256 as 64 lowercase hex characters.
  final String sha256;

  /// File size in bytes.
  final int size;

  /// File size rendered for humans (e.g. `4.4 GB`).
  final String sizeHuman;

  const HashResult({
    required this.crc32,
    required this.md5,
    required this.sha1,
    required this.sha256,
    required this.size,
    required this.sizeHuman,
  });

  Map<String, dynamic> toJson() => {
        'crc32': crc32,
        'md5': md5,
        'sha1': sha1,
        'sha256': sha256,
        'size': size,
        'size_human': sizeHuman,
      };
}

/// Computes CRC-32 / MD5 / SHA-1 / SHA-256 of a file in a single streaming
/// pass, reading fixed-size chunks instead of loading the whole file.
///
/// The file is opened once and every digest is fed the same chunk, so hashing
/// a 40 GB disc image costs one read of the data and only [chunkSize] bytes of
/// memory at any moment.
class RomHasher {
  final int chunkSize;

  const RomHasher({this.chunkSize = kHashChunkSize});

  /// Hashes [filePath], reporting progress as a percentage (0–100).
  ///
  /// Returns `null` when the file does not exist. Throws [FileSystemException]
  /// when the file exists but cannot be read.
  Future<HashResult?> hashFile(
    String filePath, {
    void Function(double percent)? onProgress,
  }) async {
    final file = File(filePath);
    if (!file.existsSync()) return null;

    final totalBytes = file.lengthSync();
    final raf = file.openSync(mode: FileMode.read);

    final md5Sink = _DigestSink();
    final sha1Sink = _DigestSink();
    final sha256Sink = _DigestSink();
    final md5Hash = md5.startChunkedConversion(md5Sink);
    final sha1Hash = sha1.startChunkedConversion(sha1Sink);
    final sha256Hash = sha256.startChunkedConversion(sha256Sink);

    var crc = 0;
    var bytesRead = 0;

    try {
      while (true) {
        final chunk = raf.readSync(chunkSize);
        if (chunk.isEmpty) break;
        bytesRead += chunk.length;
        crc = getCrc32(chunk, crc);
        md5Hash.add(chunk);
        sha1Hash.add(chunk);
        sha256Hash.add(chunk);
        if (onProgress != null && totalBytes > 0) {
          onProgress(bytesRead / totalBytes * 100.0);
        }
      }
    } finally {
      raf.closeSync();
    }

    md5Hash.close();
    sha1Hash.close();
    sha256Hash.close();

    return HashResult(
      crc32: _crc32Hex(crc),
      md5: md5Sink.value.toString(),
      sha1: sha1Sink.value.toString(),
      sha256: sha256Sink.value.toString(),
      size: totalBytes,
      sizeHuman: formatBytes(totalBytes),
    );
  }

  static String _crc32Hex(int crc) =>
      (crc & 0xFFFFFFFF).toRadixString(16).toUpperCase().padLeft(8, '0');
}

/// Minimal [Sink] capturing the single [Digest] a chunked hash conversion
/// emits on close.
class _DigestSink implements Sink<Digest> {
  late Digest value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}

/// Formats a byte count into a human-readable string (e.g. `1.5 MB`).
String formatBytes(int size) {
  double value = size.toDouble();
  for (final unit in const ['B', 'KB', 'MB', 'GB']) {
    if (value < 1024) return '${value.toStringAsFixed(1)} $unit';
    value /= 1024;
  }
  return '${value.toStringAsFixed(1)} TB';
}
