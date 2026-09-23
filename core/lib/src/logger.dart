// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:io';
import 'package:path/path.dart' as p;
import 'config.dart';

void log(String message) {
  final now = DateTime.now().toIso8601String();
  final formattedMsg = '[$now] $message';
  print(formattedMsg);

  try {
    final logDir = p.join(getDirectoryConfig(), 'logs');
    Directory(logDir).createSync(recursive: true);
    final dateStr = now.substring(0, 10);
    final logFile = File(p.join(logDir, 'openrom_$dateStr.log'));
    logFile.writeAsStringSync('$formattedMsg\n', mode: FileMode.append);
  } catch (_) {
    // Ignore logging failures
  }
}
