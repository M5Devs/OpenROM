import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:openrom_core/openrom_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('dcp_patcher_zip_slip_rejection', () {
    final tmpDir = Directory.systemTemp.createTempSync('dcp_test_');
    try {
      final outputDir = p.join(tmpDir.path, 'output');
      final discDir = p.join(tmpDir.path, 'disc');
      Directory(outputDir).createSync();
      Directory(discDir).createSync();

      File(p.join(discDir, 'track01.bin')).writeAsStringSync('dummy track data');

      final encoder = ZipFileEncoder();
      final maliciousDcp = p.join(tmpDir.path, 'malicious.dcp');
      encoder.create(maliciousDcp);

      final evilTmp = File(p.join(tmpDir.path, 'evil.txt'))
        ..writeAsStringSync('malicious payload');
      encoder.addFile(evilTmp, '../evil.txt');
      encoder.close();

      final patcher = DcpPatcher();
      final res = patcher.apply(
        dcpPath: maliciousDcp,
        discDir: discDir,
        outputDir: outputDir,
      );

      expect(res['success'], isFalse);
      expect(res['error'].toString(), contains('Malicious archive entry detected'));
    } finally {
      tmpDir.deleteSync(recursive: true);
    }
  });
}
