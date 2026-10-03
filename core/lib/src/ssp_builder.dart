// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';

import 'logger.dart' as logger;

/// Mode-1 EDC and ECC P/Q recalculation primitives (ported from ecmlib / Neill Corlett).
class EccEdc {
  late final Uint8List eccFLut;
  late final Uint8List eccBLut;
  late final Uint32List edcLut;

  EccEdc() {
    eccFLut = Uint8List(256);
    eccBLut = Uint8List(256);
    edcLut = Uint32List(256);

    for (int i = 0; i < 256; i++) {
      int edc = i;
      final j = ((i << 1) ^ ((i & 0x80) != 0 ? 0x11D : 0)) & 0xFF;
      eccFLut[i] = j;
      eccBLut[i ^ j] = i;
      for (int c = 0; c < 8; c++) {
        edc = (edc >> 1) ^ ((edc & 1) != 0 ? 0xD8018001 : 0);
      }
      edcLut[i] = edc & 0xFFFFFFFF;
    }
  }

  int generateEdc(List<int> data) {
    int edc = 0;
    for (final b in data) {
      edc = (edc >> 8) ^ edcLut[(edc ^ b) & 0xFF];
    }
    return edc & 0xFFFFFFFF;
  }

  void generateEccPq({
    required List<int> address,
    required List<int> data,
    required Uint8List ecc,
    required int majorCount,
    required int minorCount,
    required int majorMult,
    required int minorInc,
  }) {
    final size = majorCount * minorCount;
    for (int major = 0; major < majorCount; major++) {
      int index = (major >> 1) * majorMult + (major & 1);
      int eccA = 0;
      int eccB = 0;
      for (int minor = 0; minor < minorCount; minor++) {
        final temp = index < 4 ? address[index] : data[index - 4];
        index += minorInc;
        if (index >= size) {
          index -= size;
        }
        eccB ^= temp;
        eccA = eccFLut[eccA ^ temp];
      }
      eccA = eccBLut[eccFLut[eccA] ^ eccB];
      ecc[major] = eccA;
      ecc[major + majorCount] = eccA ^ eccB;
    }
  }

  /// Recalculates EDC and ECC P/Q fields for a 2352-byte Mode-1 raw sector.
  void recalculateSector(Uint8List sector) {
    if (sector.length < 2352) return;

    // 1. Calculate EDC over sector[0x00..0x810]
    final edcVal = generateEdc(sector.sublist(0, 0x810));
    sector[0x810] = edcVal & 0xFF;
    sector[0x811] = (edcVal >> 8) & 0xFF;
    sector[0x812] = (edcVal >> 16) & 0xFF;
    sector[0x813] = (edcVal >> 24) & 0xFF;

    // 2. Clear reserved bytes 0x814..0x81C
    for (int i = 0x814; i < 0x81C; i++) {
      sector[i] = 0;
    }

    // 3. Generate ECC P (172 bytes at 0x81C..0x8C8)
    final address = sector.sublist(0x0C, 0x10);
    final eccP = Uint8List(172);
    generateEccPq(
      address: address,
      data: sector.sublist(0x10, 0x81C),
      ecc: eccP,
      majorCount: 86,
      minorCount: 24,
      majorMult: 2,
      minorInc: 86,
    );
    sector.setRange(0x81C, 0x8C8, eccP);

    // 4. Generate ECC Q (104 bytes at 0x8C8..0x930)
    final eccQ = Uint8List(104);
    generateEccPq(
      address: address,
      data: sector.sublist(0x10, 0x8C8),
      ecc: eccQ,
      majorCount: 52,
      minorCount: 43,
      majorMult: 86,
      minorInc: 88,
    );
    sector.setRange(0x8C8, 0x930, eccQ);
  }
}

/// Pure Dart bsdiff 4.0 binary delta patch generator.
class BsdiffEncoder {
  /// Encodes [oldData] and [newData] into standard BSDIFF40 patch binary.
  List<int> encode(List<int> oldData, List<int> newData) {
    final oldLen = oldData.length;
    final newLen = newData.length;

    // Build suffix array for oldData
    final I = List<int>.generate(oldLen, (i) => i);
    _qsufsort(I, oldData);

    final controlBuf = BytesBuilder();
    final diffBuf = BytesBuilder();
    final extraBuf = BytesBuilder();

    int scan = 0;
    int len = 0;
    int pos = 0;
    int lastscan = 0;
    int lastpos = 0;
    int lastoffset = 0;

    final searchRes = List<int>.filled(2, 0);

    while (scan < newLen) {
      int oldscore = 0;
      int scancount = scan + len;

      for (scan += len; scan < newLen; scan++) {
        _search(I, oldData, newData, scan, 0, oldLen, searchRes);
        len = searchRes[0];
        pos = searchRes[1];

        for (; scancount < scan + len; scancount++) {
          if (scancount + lastoffset < oldLen &&
              oldData[scancount + lastoffset] == newData[scancount]) {
            oldscore++;
          }
        }

        if ((len == oldscore && len != 0) || (len > oldscore + 8)) {
          break;
        }

        if (scan + lastoffset < oldLen &&
            oldData[scan + lastoffset] == newData[scan]) {
          oldscore--;
        }
      }

      if (len != oldscore || scan == newLen) {
        int s = 0;
        int sf = 0;
        int lenf = 0;

        for (int i = 0; (lastscan + i < scan) && (lastpos + i < oldLen);) {
          if (oldData[lastpos + i] == newData[lastscan + i]) s++;
          i++;
          if (s * 2 - i > sf * 2 - lenf) {
            sf = s;
            lenf = i;
          }
        }

        int lenb = 0;
        if (scan < newLen) {
          s = 0;
          int sb = 0;
          for (int i = 1; (scan >= lastscan + i) && (pos >= i); i++) {
            if (oldData[pos - i] == newData[scan - i]) s++;
            if (s * 2 - i > sb * 2 - lenb) {
              sb = s;
              lenb = i;
            }
          }
        }

        if (lastscan + lenf > scan - lenb) {
          final overlap = (lastscan + lenf) - (scan - lenb);
          s = 0;
          int ss = 0;
          int lens = 0;
          for (int i = 0; i < overlap; i++) {
            if (newData[lastscan + lenf - overlap + i] ==
                oldData[lastpos + lenf - overlap + i]) {
              s++;
            }
            if (newData[lastscan + lenf - overlap + i] ==
                oldData[pos - lenb + i]) {
              s--;
            }
            if (s > ss) {
              ss = s;
              lens = i + 1;
            }
          }
          lenf += lens - overlap;
          lenb -= lens;
        }

        for (int i = 0; i < lenf; i++) {
          diffBuf.addByte(
            (newData[lastscan + i] - oldData[lastpos + i]) & 0xFF,
          );
        }

        for (int i = 0; i < (scan - lenb) - (lastscan + lenf); i++) {
          extraBuf.addByte(newData[lastscan + lenf + i]);
        }

        final ctrlX = lenf;
        final ctrlY = (scan - lenb) - (lastscan + lenf);
        final ctrlZ = (pos - lenb) - (lastpos + lenf);

        controlBuf.add(_encodeOffT(ctrlX));
        controlBuf.add(_encodeOffT(ctrlY));
        controlBuf.add(_encodeOffT(ctrlZ));

        lastscan = scan - lenb;
        lastpos = pos - lenb;
        lastoffset = pos - scan;
      }
    }

    final compressedCtrl = BZip2Encoder().encode(controlBuf.takeBytes());
    final compressedDiff = BZip2Encoder().encode(diffBuf.takeBytes());
    final compressedExtra = BZip2Encoder().encode(extraBuf.takeBytes());

    final header = BytesBuilder();
    // BSDIFF40 magic
    header.add(ascii.encode('BSDIFF40'));
    header.add(_encodeOffT(compressedCtrl.length));
    header.add(_encodeOffT(compressedDiff.length));
    header.add(_encodeOffT(newLen));

    header.add(compressedCtrl);
    header.add(compressedDiff);
    header.add(compressedExtra);

    return header.takeBytes();
  }

  static Uint8List _encodeOffT(int val) {
    final buf = Uint8List(8);
    int v = val < 0 ? -val : val;
    for (int i = 0; i < 7; i++) {
      buf[i] = v & 0xFF;
      v >>= 8;
    }
    buf[7] = v & 0x7F;
    if (val < 0) {
      buf[7] |= 0x80;
    }
    return buf;
  }

  void _qsufsort(List<int> I, List<int> V) {
    I.sort((a, b) {
      int i = a;
      int j = b;
      while (i < V.length && j < V.length) {
        if (V[i] != V[j]) return V[i].compareTo(V[j]);
        i++;
        j++;
      }
      return (V.length - a).compareTo(V.length - b);
    });
  }

  void _search(
    List<int> I,
    List<int> oldData,
    List<int> newData,
    int newPos,
    int st,
    int en,
    List<int> result,
  ) {
    if (en - st < 2) {
      final x = _matchLen(oldData, I[st], newData, newPos);
      final y = _matchLen(oldData, I[en < I.length ? en : st], newData, newPos);
      if (x > y) {
        result[0] = x;
        result[1] = I[st];
      } else {
        result[0] = y;
        result[1] = I[en < I.length ? en : st];
      }
      return;
    }

    final m = st + (en - st) ~/ 2;
    if (_memcmp(oldData, I[m], newData, newPos) < 0) {
      _search(I, oldData, newData, newPos, m, en, result);
    } else {
      _search(I, oldData, newData, newPos, st, m, result);
    }
  }

  int _matchLen(List<int> oldData, int oldPos, List<int> newData, int newPos) {
    int i = 0;
    while (oldPos + i < oldData.length &&
        newPos + i < newData.length &&
        oldData[oldPos + i] == newData[newPos + i]) {
      i++;
    }
    return i;
  }

  int _memcmp(List<int> oldData, int oldPos, List<int> newData, int newPos) {
    int i = 0;
    while (oldPos + i < oldData.length && newPos + i < newData.length) {
      if (oldData[oldPos + i] != newData[newPos + i]) {
        return oldData[oldPos + i].compareTo(newData[newPos + i]);
      }
      i++;
    }
    return (oldData.length - oldPos).compareTo(newData.length - newPos);
  }
}

class IsoDirEntry {
  final String filename;
  final int lba;
  final int size;

  IsoDirEntry({required this.filename, required this.lba, required this.size});
}

/// Helper class for reading ISO9660 root directory from raw 2352-byte sector BIN tracks.
class Iso9660Reader {
  static const int sectorRaw = 2352;
  static const int sectorData = 2048;
  static const int dataOff = 0x10;

  static Map<String, IsoDirEntry> readRootDir(File binFile) {
    final raf = binFile.openSync(mode: FileMode.read);
    try {
      final pvdPayload = _readPayload(raf, 16, 1);
      if (pvdPayload.length < 2048) {
        throw FormatException('BIN file too small or unreadable.');
      }

      // Check CD001 magic
      final magic = utf8.decode(pvdPayload.sublist(1, 6), allowMalformed: true);
      if (magic != 'CD001' || pvdPayload[0] != 0x01) {
        throw FormatException(
          'Not a valid ISO9660 image (missing CD001 PVD at LBA 16).',
        );
      }

      final rootRec = pvdPayload.sublist(156, 156 + 34);
      final rootLba = _readUint32LE(rootRec, 2);
      final rootSize = _readUint32LE(rootRec, 10);

      final nSectors = (rootSize + sectorData - 1) ~/ sectorData;
      final dirData = _readPayload(raf, rootLba, nSectors);
      final buf = dirData.sublist(0, rootSize.clamp(0, dirData.length));

      return _parseDirRecords(buf);
    } finally {
      raf.closeSync();
    }
  }

  static Uint8List readIsoFile(File binFile, int lba, int size) {
    final raf = binFile.openSync(mode: FileMode.read);
    try {
      final nSectors = (size + sectorData - 1) ~/ sectorData;
      final payload = _readPayload(raf, lba, nSectors);
      return Uint8List.sublistView(payload, 0, size.clamp(0, payload.length));
    } finally {
      raf.closeSync();
    }
  }

  static Uint8List _readPayload(RandomAccessFile raf, int lba, int nSectors) {
    final result = Uint8List(nSectors * sectorData);
    final sectorBuf = Uint8List(sectorRaw);

    for (int i = 0; i < nSectors; i++) {
      final pos = (lba + i) * sectorRaw;
      if (pos >= raf.lengthSync()) break;
      raf.setPositionSync(pos);
      final readBytes = raf.readIntoSync(sectorBuf);
      if (readBytes < sectorRaw) break;

      result.setRange(
        i * sectorData,
        (i + 1) * sectorData,
        sectorBuf.sublist(dataOff, dataOff + sectorData),
      );
    }
    return result;
  }

  static Map<String, IsoDirEntry> _parseDirRecords(Uint8List buf) {
    final out = <String, IsoDirEntry>{};
    int pos = 0;

    while (pos < buf.length) {
      final recLen = buf[pos];
      if (recLen == 0) {
        final next = ((pos ~/ sectorData) + 1) * sectorData;
        if (next >= buf.length) break;
        pos = next;
        continue;
      }

      if (pos + recLen > buf.length) break;

      final rec = buf.sublist(pos, pos + recLen);
      final lba = _readUint32LE(rec, 2);
      final size = _readUint32LE(rec, 10);
      final flags = rec[25];
      final nameLen = rec[32];

      if (33 + nameLen <= rec.length) {
        final nameBytes = rec.sublist(33, 33 + nameLen);
        if (!(nameLen == 1 && (nameBytes[0] == 0x00 || nameBytes[0] == 0x01))) {
          final isDir = (flags & 0x02) != 0;
          if (!isDir) {
            final rawName = utf8.decode(nameBytes, allowMalformed: true);
            final filename = rawName.split(';').first;
            out[filename] = IsoDirEntry(
              filename: filename,
              lba: lba,
              size: size,
            );
          }
        }
      }

      pos += recLen;
    }

    return out;
  }

  static int _readUint32LE(List<int> bytes, int offset) {
    return bytes[offset] |
        (bytes[offset + 1] << 8) |
        (bytes[offset + 2] << 16) |
        (bytes[offset + 3] << 24);
  }
}

/// Sega Saturn Patcher (.ssp) patch builder.
/// Compares two raw 2352-byte sector BIN tracks (original and modified)
/// and produces a .ssp (ZIP archive containing bsdiff patches per changed file).
class SspBuilder {
  final File originalBin;
  final File modifiedBin;
  final File outputFile;
  final String version;
  final void Function(String msg)? onLog;
  final void Function(double pct)? onProgress;

  SspBuilder({
    required this.originalBin,
    required this.modifiedBin,
    required this.outputFile,
    this.version = '1.0.0',
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
    if (!originalBin.existsSync()) {
      throw FormatException('Original BIN file not found: ${originalBin.path}');
    }
    if (!modifiedBin.existsSync()) {
      throw FormatException('Modified BIN file not found: ${modifiedBin.path}');
    }

    _log('[SSP Builder] Scanning ISO9660 directory structures...');
    _updateProgress(5.0);

    final origDirMap = Iso9660Reader.readRootDir(originalBin);
    final modDirMap = Iso9660Reader.readRootDir(modifiedBin);

    if (modDirMap.isEmpty) {
      throw FormatException('No files found in ISO9660 root directory.');
    }

    final md5Lines = <String>[];
    final archive = Archive();
    final bsdiff = BsdiffEncoder();

    final modEntries = modDirMap.entries.toList();
    int changedCount = 0;

    for (int i = 0; i < modEntries.length; i++) {
      final entry = modEntries[i];
      final filename = entry.key;
      final modDirEntry = entry.value;

      final pct = 5.0 + ((i + 1) / modEntries.length) * 85.0;
      _updateProgress(pct);

      if (!origDirMap.containsKey(filename)) {
        _log(
          '[SSP Builder WARN] File $filename present in modified BIN but missing in original. Skipping.',
        );
        continue;
      }

      final origDirEntry = origDirMap[filename]!;

      final origBytes = Iso9660Reader.readIsoFile(
        originalBin,
        origDirEntry.lba,
        origDirEntry.size,
      );
      final modBytes = Iso9660Reader.readIsoFile(
        modifiedBin,
        modDirEntry.lba,
        modDirEntry.size,
      );

      if (_bytesEqual(origBytes, modBytes)) {
        // File unchanged
        continue;
      }

      if (origBytes.length != modBytes.length) {
        throw FormatException(
          'File $filename size mismatch (original ${origBytes.length} != modified ${modBytes.length}). SSP format only supports same-size file replacements.',
        );
      }

      _log(
        '[SSP Builder] Encoding bsdiff diff for $filename (${origBytes.length} bytes)...',
      );

      final origMd5 = md5.convert(origBytes).toString().toUpperCase();
      md5Lines.add('$filename: $origMd5');

      final patchData = bsdiff.encode(origBytes, modBytes);
      final dfrFilename = '$filename._DFR';

      archive.addFile(ArchiveFile(dfrFilename, patchData.length, patchData));

      changedCount++;
    }

    _log(
      '[SSP Builder] Packaging SSP archive with $changedCount patch entries...',
    );
    _updateProgress(92.0);

    // changes.md5
    final changesMd5Content = '${md5Lines.join('\n')}\n';
    final changesBytes = utf8.encode(changesMd5Content);
    archive.addFile(
      ArchiveFile('changes.md5', changesBytes.length, changesBytes),
    );

    // version.txt
    final versionBytes = utf8.encode('$version\n');
    archive.addFile(
      ArchiveFile('version.txt', versionBytes.length, versionBytes),
    );

    outputFile.parent.createSync(recursive: true);
    final zipData = ZipEncoder().encode(archive);
    if (zipData == null) {
      throw FormatException('Failed to encode ZIP archive for SSP.');
    }

    outputFile.writeAsBytesSync(zipData);

    _updateProgress(100.0);
    _log(
      '[SSP Builder] Complete. Generated .ssp with $changedCount modified files.',
    );
  }

  bool _bytesEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
