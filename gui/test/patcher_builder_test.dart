// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gui/patcher/bps_builder.dart';
import 'package:gui/patcher/bps_patcher.dart';
import 'package:gui/patcher/ebp_builder.dart';
import 'package:gui/patcher/ebp_patcher.dart';
import 'package:gui/patcher/ips32_builder.dart';
import 'package:gui/patcher/ips_builder.dart';
import 'package:gui/patcher/ips_patcher.dart';
import 'package:gui/patcher/patcher.dart';
import 'package:gui/patcher/ups_builder.dart';
import 'package:gui/patcher/ups_patcher.dart';
import 'package:gui/patcher/xdelta_builder.dart';
import 'package:gui/patcher/xdelta_patcher.dart';
import 'package:gui/utils/config.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('patcher_builder_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('IPS Builder Tests', () {
    test('IPS Round-trip test (< 1MB)', () async {
      final origFile = File('${tempDir.path}/orig.bin');
      final modFile = File('${tempDir.path}/mod.bin');
      final patchFile = File('${tempDir.path}/patch.ips');
      final outFile = File('${tempDir.path}/out.bin');

      final origData = Uint8List.fromList(List.generate(1000, (i) => i % 256));
      final modData = Uint8List.fromList(List.from(origData));
      // Modify 10 bytes at offset 100
      for (int i = 0; i < 10; i++) {
        modData[100 + i] = (modData[100 + i] + 5) % 256;
      }

      await origFile.writeAsBytes(origData);
      await modFile.writeAsBytes(modData);

      // Build patch
      final builder = IpsBuilder(
        originalFile: origFile,
        modifiedFile: modFile,
        outputFile: patchFile,
      );
      await builder.build();

      expect(await patchFile.exists(), isTrue);

      // Verify header magic "PATCH" and footer "EOF"
      final patchBytes = await patchFile.readAsBytes();
      expect(patchBytes.sublist(0, 5), equals([0x50, 0x41, 0x54, 0x43, 0x48])); // PATCH
      expect(
        patchBytes.sublist(patchBytes.length - 3),
        equals([0x45, 0x4F, 0x46]), // EOF
      );

      // Apply patch and verify round-trip result == modified
      final patcher = IpsPatcher(
        patchFile: patchFile,
        romFile: origFile,
        outputFile: outFile,
      );
      await patcher.apply();

      final outData = await outFile.readAsBytes();
      expect(outData, equals(modData));
    });

    test('IPS size limit test (> 16MB throws PatchException)', () async {
      final origFile = File('${tempDir.path}/large_orig.bin');
      final modFile = File('${tempDir.path}/large_mod.bin');
      final patchFile = File('${tempDir.path}/large.ips');

      final rafOrig = await origFile.open(mode: FileMode.write);
      await rafOrig.truncate(0xFFFFFF + 10);
      await rafOrig.close();

      final rafMod = await modFile.open(mode: FileMode.write);
      await rafMod.truncate(1000);
      await rafMod.close();

      final builder = IpsBuilder(
        originalFile: origFile,
        modifiedFile: modFile,
        outputFile: patchFile,
      );

      expect(
        () async => await builder.build(),
        throwsA(
          isA<PatchException>().having(
            (e) => e.message,
            'message',
            contains('File too large for IPS format'),
          ),
        ),
      );
    });
  });

  group('IPS32 Builder Tests', () {
    test('IPS32 Round-trip test', () async {
      final origFile = File('${tempDir.path}/orig.bin');
      final modFile = File('${tempDir.path}/mod.bin');
      final patchFile = File('${tempDir.path}/patch.ips32');
      final outFile = File('${tempDir.path}/out.bin');

      final origData = Uint8List.fromList(List.generate(1500, (i) => (i * 7) % 256));
      final modData = Uint8List.fromList(List.from(origData));
      // Modify 15 bytes at offset 300
      for (int i = 0; i < 15; i++) {
        modData[300 + i] = (modData[300 + i] + 42) % 256;
      }

      await origFile.writeAsBytes(origData);
      await modFile.writeAsBytes(modData);

      final builder = IPS32Builder(
        originalFile: origFile,
        modifiedFile: modFile,
        outputFile: patchFile,
      );
      await builder.build();

      expect(await patchFile.exists(), isTrue);

      // Verify header magic "IPS32" and footer "EEOF"
      final patchBytes = await patchFile.readAsBytes();
      expect(patchBytes.sublist(0, 5), equals([0x49, 0x50, 0x53, 0x33, 0x32])); // IPS32
      expect(
        patchBytes.sublist(patchBytes.length - 4),
        equals([0x45, 0x45, 0x4F, 0x46]), // EEOF
      );

      final patcher = IpsPatcher(
        patchFile: patchFile,
        romFile: origFile,
        outputFile: outFile,
      );
      await patcher.apply();

      final outData = await outFile.readAsBytes();
      expect(outData, equals(modData));
    });
  });

  group('EBP Builder Tests', () {
    test('EBP Round-trip test', () async {
      final origFile = File('${tempDir.path}/orig.bin');
      final modFile = File('${tempDir.path}/mod.bin');
      final patchFile = File('${tempDir.path}/patch.ebp');
      final outFile = File('${tempDir.path}/out.bin');

      final origData = Uint8List.fromList(List.generate(800, (i) => (i * 11) % 256));
      final modData = Uint8List.fromList(List.from(origData));
      // Modify 8 bytes at offset 200
      for (int i = 0; i < 8; i++) {
        modData[200 + i] = (modData[200 + i] + 13) % 256;
      }

      await origFile.writeAsBytes(origData);
      await modFile.writeAsBytes(modData);

      final builder = EbpBuilder(
        originalFile: origFile,
        modifiedFile: modFile,
        outputFile: patchFile,
      );
      await builder.build();

      expect(await patchFile.exists(), isTrue);

      final patcher = EbpPatcher(
        patchFile: patchFile,
        romFile: origFile,
        outputFile: outFile,
      );
      final report = await patcher.apply();

      expect(report.format, equals('EBP'));

      final outData = await outFile.readAsBytes();
      expect(outData, equals(modData));
    });
  });

  group('UPS Builder Tests', () {
    test('UPS Round-trip test (forward and reverse)', () async {
      final origFile = File('${tempDir.path}/orig.bin');
      final modFile = File('${tempDir.path}/mod.bin');
      final patchFile = File('${tempDir.path}/patch.ups');
      final forwardOutFile = File('${tempDir.path}/forward_out.bin');
      final reverseOutFile = File('${tempDir.path}/reverse_out.bin');

      final origData = Uint8List.fromList(List.generate(3000, (i) => (i * 13) % 256));
      final modData = Uint8List.fromList(List.from(origData));
      // Modify 25 bytes at offset 1200
      for (int i = 0; i < 25; i++) {
        modData[1200 + i] = (modData[1200 + i] + 77) % 256;
      }

      await origFile.writeAsBytes(origData);
      await modFile.writeAsBytes(modData);

      final builder = UpsBuilder(
        originalFile: origFile,
        modifiedFile: modFile,
        outputFile: patchFile,
      );
      await builder.build();

      expect(await patchFile.exists(), isTrue);

      // Forward patch test: original + patch -> modified
      final forwardPatcher = UpsPatcher(
        patchFile: patchFile,
        romFile: origFile,
        outputFile: forwardOutFile,
      );
      final forwardReport = await forwardPatcher.apply();
      expect(forwardReport.format, equals('UPS'));

      final forwardOutData = await forwardOutFile.readAsBytes();
      expect(forwardOutData, equals(modData));

      // Reverse patch test: modified + patch -> original
      final reversePatcher = UpsPatcher(
        patchFile: patchFile,
        romFile: modFile,
        outputFile: reverseOutFile,
      );
      final reverseReport = await reversePatcher.apply();
      expect(reverseReport.format, equals('UPS'));

      final reverseOutData = await reverseOutFile.readAsBytes();
      expect(reverseOutData, equals(origData));
    });
  });

  group('BPS Builder Tests', () {
    test('BPS Round-trip test', () async {
      final origFile = File('${tempDir.path}/orig.bin');
      final modFile = File('${tempDir.path}/mod.bin');
      final patchFile = File('${tempDir.path}/patch.bps');
      final outFile = File('${tempDir.path}/out.bin');

      final origData = Uint8List.fromList(List.generate(2000, (i) => (i * 3) % 256));
      final modData = Uint8List.fromList(List.from(origData));
      // Modify 20 bytes at offset 500
      for (int i = 0; i < 20; i++) {
        modData[500 + i] = (modData[500 + i] + 17) % 256;
      }

      await origFile.writeAsBytes(origData);
      await modFile.writeAsBytes(modData);

      // Build patch
      final builder = BpsBuilder(
        originalFile: origFile,
        modifiedFile: modFile,
        outputFile: patchFile,
      );
      await builder.build();

      expect(await patchFile.exists(), isTrue);

      // Apply patch (validates CRCs implicitly)
      final patcher = BpsPatcher(
        patchFile: patchFile,
        romFile: origFile,
        outputFile: outFile,
      );
      final report = await patcher.apply();

      expect(report.format, equals('BPS'));

      final outData = await outFile.readAsBytes();
      expect(outData, equals(modData));
    });
  });

  group('xdelta Builder Tests', () {
    test('xdelta Round-trip test', () async {
      final binary = AppConfig.xdelta3Path;
      if (!await File(binary).exists()) {
        // Skip xdelta test if binary is not bundled in local dev environment
        return;
      }

      final origFile = File('${tempDir.path}/orig.bin');
      final modFile = File('${tempDir.path}/mod.bin');
      final patchFile = File('${tempDir.path}/patch.xdelta');
      final outFile = File('${tempDir.path}/out.bin');

      final origData = Uint8List.fromList(List.generate(5000, (i) => i % 256));
      final modData = Uint8List.fromList(List.from(origData));
      // Modify 10 bytes
      for (int i = 0; i < 10; i++) {
        modData[2500 + i] = (modData[2500 + i] + 99) % 256;
      }

      await origFile.writeAsBytes(origData);
      await modFile.writeAsBytes(modData);

      final builder = XdeltaBuilder(
        originalFile: origFile,
        modifiedFile: modFile,
        outputFile: patchFile,
      );
      await builder.build();

      expect(await patchFile.exists(), isTrue);

      final patcher = XdeltaPatcher(
        patchFile: patchFile,
        romFile: origFile,
        outputFile: outFile,
      );
      await patcher.apply();

      final outData = await outFile.readAsBytes();
      expect(outData, equals(modData));
    });
  });
}
