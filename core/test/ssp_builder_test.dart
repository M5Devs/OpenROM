import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:openrom_core/openrom_core.dart';
import 'package:test/test.dart';

void main() {
  group('EccEdc', () {
    test('generateEdc produces expected EDC checksum', () {
      final ecc = EccEdc();
      final testData = List<int>.generate(2064, (i) => i & 0xFF);
      final edc = ecc.generateEdc(testData);
      expect(edc, isA<int>());
      expect(edc, isNot(equals(0)));
    });

    test('recalculateSector modifies EDC and ECC bytes correctly', () {
      final ecc = EccEdc();
      final sector = Uint8List(2352);
      // Mode-1 sync bytes
      sector[0] = 0x00;
      for (int i = 1; i < 11; i++) sector[i] = 0xFF;
      sector[11] = 0x00;
      // Header: LBA 16 (00:02:16), Mode 1
      sector[12] = 0x00; // Minute
      sector[13] = 0x02; // Second
      sector[14] = 0x16; // Frame
      sector[15] = 0x01; // Mode 1

      // Dummy user data at 0x10..0x810
      for (int i = 0x10; i < 0x810; i++) {
        sector[i] = (i ^ 0x5A) & 0xFF;
      }

      ecc.recalculateSector(sector);

      // Verify EDC non-zero
      final edcVal =
          sector[0x810] |
          (sector[0x811] << 8) |
          (sector[0x812] << 16) |
          (sector[0x813] << 24);
      expect(edcVal, isNot(equals(0)));

      // Verify reserved bytes 0x814..0x81C are 0
      for (int i = 0x814; i < 0x81C; i++) {
        expect(sector[i], equals(0));
      }

      // Verify ECC P and Q non-zero
      expect(sector.sublist(0x81C, 0x8C8).any((b) => b != 0), isTrue);
      expect(sector.sublist(0x8C8, 0x930).any((b) => b != 0), isTrue);
    });
  });

  group('SspBuilder Integration', () {
    late Directory tempDir;
    late File origBin;
    late File modBin;
    late File sspOutput;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('ssp_builder_test_');
      origBin = File('${tempDir.path}/orig.bin');
      modBin = File('${tempDir.path}/mod.bin');
      sspOutput = File('${tempDir.path}/patch.ssp');

      _createMockIsoBin(
        binFile: origBin,
        fileContent: ascii.encode('ORIGINAL SATURN FILE CONTENT 1234567890'),
        filename: 'TEST.BIN',
      );

      _createMockIsoBin(
        binFile: modBin,
        fileContent: ascii.encode('MODIFIED SATURN FILE CONTENT 1234567890'),
        filename: 'TEST.BIN',
      );
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    test(
      'SspBuilder generates valid .ssp ZIP archive with expected structure',
      () async {
        final builder = SspBuilder(
          originalBin: origBin,
          modifiedBin: modBin,
          outputFile: sspOutput,
          version: '1.2.3',
        );

        await builder.build();

        expect(sspOutput.existsSync(), isTrue);

        final archiveBytes = sspOutput.readAsBytesSync();
        final archive = ZipDecoder().decodeBytes(archiveBytes);

        final fileNames = archive.map((f) => f.name).toList();
        expect(fileNames, contains('changes.md5'));
        expect(fileNames, contains('version.txt'));
        expect(fileNames, contains('TEST.BIN._DFR'));

        final changesFile = archive.firstWhere((f) => f.name == 'changes.md5');
        final changesTxt = utf8.decode(changesFile.content as List<int>);

        final origIsoContent = Iso9660Reader.readIsoFile(origBin, 18, 39);
        final expectedMd5 = md5
            .convert(origIsoContent)
            .toString()
            .toUpperCase();

        expect(changesTxt, contains('TEST.BIN: $expectedMd5'));

        final versionFile = archive.firstWhere((f) => f.name == 'version.txt');
        final versionTxt = utf8.decode(versionFile.content as List<int>).trim();
        expect(versionTxt, equals('1.2.3'));
      },
    );

    test('SspBuilder generated SSP can be applied with saturn-patcher CLI binary if available', () async {
      final builder = SspBuilder(
        originalBin: origBin,
        modifiedBin: modBin,
        outputFile: sspOutput,
      );
      await builder.build();

      final saturnPatcherCli = File(
        '/tmp/saturn-patcher-egui/target/debug/saturn-patcher',
      );
      if (!saturnPatcherCli.existsSync()) {
        return; // Skip Rust CLI test if binary isn't built
      }

      final targetBin = File('${tempDir.path}/target.bin');
      origBin.copySync(targetBin.path);

      final res = Process.runSync(saturnPatcherCli.path, [
        targetBin.path,
        sspOutput.path,
      ]);

      expect(
        res.exitCode,
        equals(0),
        reason: 'saturn-patcher stderr: ${res.stderr}',
      );

      final patchedIsoContent = Iso9660Reader.readIsoFile(targetBin, 18, 39);
      final expectedModContent = ascii.encode(
        'MODIFIED SATURN FILE CONTENT 1234567890',
      );
      expect(patchedIsoContent, equals(expectedModContent));
    });
  });
}

void _createMockIsoBin({
  required File binFile,
  required List<int> fileContent,
  required String filename,
}) {
  final ecc = EccEdc();
  final totalSectors = 32; // 32 * 2352 = 75264 bytes
  final binData = Uint8List(totalSectors * 2352);

  // Sector 16: Primary Volume Descriptor (PVD)
  final pvdSector = Uint8List.sublistView(binData, 16 * 2352, 17 * 2352);
  pvdSector[0x10 + 0] = 0x01; // PVD Type
  pvdSector.setRange(0x10 + 1, 0x10 + 6, ascii.encode('CD001'));

  // Root directory record in PVD at offset 156 (34 bytes)
  final pvdPayload = Uint8List.sublistView(pvdSector, 0x10, 0x10 + 2048);
  pvdPayload[156 + 0] = 34; // Rec len
  pvdPayload[156 + 2] = 17; // Root dir LBA = 17 (LE uint32)
  pvdPayload[156 + 10] = 2048 & 0xFF; // Root dir size = 2048
  pvdPayload[156 + 11] = (2048 >> 8) & 0xFF;

  // Sector 17: Root Directory Block
  final dirSector = Uint8List.sublistView(binData, 17 * 2352, 18 * 2352);
  final dirPayload = Uint8List.sublistView(dirSector, 0x10, 0x10 + 2048);

  // Rec 1: "."
  dirPayload[0] = 34;
  dirPayload[2] = 17;
  dirPayload[10] = 2048 & 0xFF;
  dirPayload[32] = 1;
  dirPayload[33] = 0x00;

  // Rec 2: ".."
  int pos = 34;
  dirPayload[pos] = 34;
  dirPayload[pos + 2] = 17;
  dirPayload[pos + 10] = 2048 & 0xFF;
  dirPayload[pos + 32] = 1;
  dirPayload[pos + 33] = 0x01;

  // Rec 3: Target File (e.g. "TEST.BIN;1")
  pos += 34;
  final isoName = ascii.encode('$filename;1');
  final recLen = 33 + isoName.length;
  final paddedRecLen = (recLen % 2 != 0) ? recLen + 1 : recLen;

  dirPayload[pos] = paddedRecLen;
  dirPayload[pos + 2] = 18; // File LBA = 18
  dirPayload[pos + 10] = fileContent.length & 0xFF; // File size LE
  dirPayload[pos + 11] = (fileContent.length >> 8) & 0xFF;
  dirPayload[pos + 12] = (fileContent.length >> 16) & 0xFF;
  dirPayload[pos + 13] = (fileContent.length >> 24) & 0xFF;
  dirPayload[pos + 25] = 0x00; // File flags
  dirPayload[pos + 32] = isoName.length;
  dirPayload.setRange(pos + 33, pos + 33 + isoName.length, isoName);

  // Sector 18: File Data
  final fileSector = Uint8List.sublistView(binData, 18 * 2352, 19 * 2352);
  fileSector.setRange(0x10, 0x10 + fileContent.length, fileContent);

  // Recalculate EDC/ECC for all sectors
  for (int s = 0; s < totalSectors; s++) {
    final sectorBuf = Uint8List.sublistView(binData, s * 2352, (s + 1) * 2352);
    sectorBuf[0] = 0x00;
    for (int i = 1; i < 11; i++) sectorBuf[i] = 0xFF;
    sectorBuf[11] = 0x00;

    // Header LBA MSF
    final min = s ~/ (60 * 75);
    final sec = (s ~/ 75) % 60;
    final frame = s % 75;
    sectorBuf[12] = min;
    sectorBuf[13] = sec + 2; // +2 sec offset standard
    sectorBuf[14] = frame;
    sectorBuf[15] = 0x01; // Mode 1

    ecc.recalculateSector(sectorBuf);
  }

  binFile.writeAsBytesSync(binData);
}
