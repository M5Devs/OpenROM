import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gui/patcher/patch_manifest.dart';
import 'package:gui/patcher/patcher.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('patch_manifest_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('writes a sidecar with base and target ROM identities', () async {
    final base = File('${tempDir.path}/base.rom')
      ..writeAsBytesSync([1, 2, 3, 4]);
    final target = File('${tempDir.path}/target.rom')
      ..writeAsBytesSync([1, 9, 3, 4]);
    final patch = File('${tempDir.path}/change.ips')..writeAsBytesSync([0]);

    final manifest = PatchManifest(
      format: 'IPS',
      baseRom: await RomIdentity.fromFile(base),
      targetRom: await RomIdentity.fromFile(target),
    );
    await manifest.writeForPatch(patch);

    final loaded = await PatchManifest.readForPatch(patch);
    expect(loaded, isNotNull);
    expect(loaded!.format, 'IPS');
    expect(loaded.baseRom.sizeBytes, 4);
    expect(loaded.baseRom.sha256, isNotEmpty);
    expect(File('${patch.path}.json').existsSync(), isTrue);
  });

  test('rejects a base ROM with a different hash', () async {
    final base = File('${tempDir.path}/base.rom')
      ..writeAsBytesSync([1, 2, 3, 4]);
    final wrong = File('${tempDir.path}/wrong.rom')
      ..writeAsBytesSync([1, 2, 3, 5]);
    final target = File('${tempDir.path}/target.rom')
      ..writeAsBytesSync([1, 9, 3, 4]);
    final patch = File('${tempDir.path}/change.ips')..writeAsBytesSync([0]);

    final manifest = PatchManifest(
      format: 'IPS',
      baseRom: await RomIdentity.fromFile(base),
      targetRom: await RomIdentity.fromFile(target),
    );
    await manifest.writeForPatch(patch);
    final loaded = await PatchManifest.readForPatch(patch);

    expect(
      () => loaded!.validateBase(wrong),
      throwsA(isA<PatchException>()),
    );
  });
}
