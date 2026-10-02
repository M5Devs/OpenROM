import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:openrom_core/openrom_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tmpDir;
  late Directory origDir;
  late Directory modDir;
  late Directory outputDir;
  late File outputDcp;

  setUp(() {
    tmpDir = Directory.systemTemp.createTempSync('dcp_builder_test_');
    origDir = Directory(p.join(tmpDir.path, 'orig'))..createSync();
    modDir = Directory(p.join(tmpDir.path, 'mod'))..createSync();
    outputDir = Directory(p.join(tmpDir.path, 'output'))..createSync();
    outputDcp = File(p.join(tmpDir.path, 'test_patch.dcp'));

    // Create original disc files
    File(p.join(origDir.path, 'bootsector', 'IP.BIN'))
      ..createSync(recursive: true)
      ..writeAsStringSync('ORIGINAL_BOOTSECTOR_IPBIN_HEADER_12345');
    File(p.join(origDir.path, '1ST_READ.BIN'))
      ..writeAsStringSync('ORIGINAL_GAME_CODE_ABCDEF');
    File(p.join(origDir.path, 'DATA', 'CONFIG.TXT'))
      ..createSync(recursive: true)
      ..writeAsStringSync('SAME_CONFIG_DATA');

    // Create modified disc files
    File(p.join(modDir.path, 'bootsector', 'IP.BIN'))
      ..createSync(recursive: true)
      ..writeAsStringSync('MODIFIED_BOOTSECTOR_IPBIN_HEADER_67890');
    File(p.join(modDir.path, '1ST_READ.BIN'))
      ..writeAsStringSync('MODIFIED_GAME_CODE_XYZ123');
    File(p.join(modDir.path, 'DATA', 'CONFIG.TXT'))
      ..createSync(recursive: true)
      ..writeAsStringSync('SAME_CONFIG_DATA');
    File(p.join(modDir.path, 'DATA', 'NEWFILE.BIN'))
      ..createSync(recursive: true)
      ..writeAsStringSync('NEW_FILE_ADDED_VERBATIM');
  });

  tearDown(() {
    try {
      tmpDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  test('DcpBuilder creates valid .dcp archive with verbatim entries', () async {
    final builder = DcpBuilder(
      originalDir: origDir,
      modifiedDir: modDir,
      outputFile: outputDcp,
      useXdelta: false,
    );

    await builder.build();

    expect(outputDcp.existsSync(), isTrue);

    final bytes = outputDcp.readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);

    final entryNames = archive.files.map((f) => f.name).toList();

    expect(entryNames, contains('bootsector/IP.BIN'));
    expect(entryNames, contains('1ST_READ.BIN'));
    expect(entryNames, contains('DATA/NEWFILE.BIN'));
    expect(entryNames, isNot(contains('DATA/CONFIG.TXT')));
  });

  test('DcpBuilder and DcpPatcher roundtrip patching test', () async {
    final builder = DcpBuilder(
      originalDir: origDir,
      modifiedDir: modDir,
      outputFile: outputDcp,
      useXdelta: false,
    );

    await builder.build();

    final patcher = DcpPatcher();
    final result = patcher.apply(
      dcpPath: outputDcp.path,
      discDir: origDir.path,
      outputDir: outputDir.path,
    );

    expect(result['success'], isTrue);

    final patchedIpBin = File(p.join(outputDir.path, 'IP.BIN')).readAsStringSync();
    final patched1stRead = File(p.join(outputDir.path, '1ST_READ.BIN')).readAsStringSync();
    final patchedConfig = File(p.join(outputDir.path, 'DATA', 'CONFIG.TXT')).readAsStringSync();
    final patchedNewFile = File(p.join(outputDir.path, 'DATA', 'NEWFILE.BIN')).readAsStringSync();

    expect(patchedIpBin, equals('MODIFIED_BOOTSECTOR_IPBIN_HEADER_67890'));
    expect(patched1stRead, equals('MODIFIED_GAME_CODE_XYZ123'));
    expect(patchedConfig, equals('SAME_CONFIG_DATA'));
    expect(patchedNewFile, equals('NEW_FILE_ADDED_VERBATIM'));
  });
}
