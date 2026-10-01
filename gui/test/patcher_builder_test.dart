// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gui/patcher/bps_builder.dart';
import 'package:gui/patcher/bps_patcher.dart';
import 'package:gui/patcher/ips_builder.dart';
import 'package:gui/patcher/ips_patcher.dart';
import 'package:gui/patcher/patcher.dart';
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
