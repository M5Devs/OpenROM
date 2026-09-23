// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:convert';
import 'dart:io';
import 'detector.dart' as detector;
import 'logger.dart' as logger;

bool verifyChd(String chdPath, {void Function(String msg)? onLog}) {
  final logCb = onLog ?? logger.log;
  final file = File(chdPath);
  if (!file.existsSync()) {
    logCb('[ERROR] CHD file not found: $chdPath');
    return false;
  }

  final chdmanPath = detector.getChdmanPath();
  logCb('[VERIFY] Running chdman verify on $chdPath...');

  try {
    final result = Process.runSync(chdmanPath, ['verify', '-i', chdPath]);
    final output = '${result.stdout}\n${result.stderr}';
    final lines = const LineSplitter().convert(output);

    for (final line in lines) {
      if (line.trim().isNotEmpty) {
        logCb('  ${line.trim()}');
      }
    }

    if (result.exitCode == 0) {
      final lower = output.toLowerCase();
      if (lower.contains('is valid') ||
          lower.contains('integrity verified') ||
          lower.contains('raw sha1')) {
        return true;
      }
    }
    return result.exitCode == 0;
  } catch (e) {
    logCb('[ERROR] Failed to execute chdman verify: $e');
    return false;
  }
}
