// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import '../utils/config.dart';
import 'patcher.dart';

/// xdelta3 patch creator — delegates to the xdelta3 binary via subprocess.
class XdeltaBuilder {
  final File originalFile;
  final File modifiedFile;
  final File outputFile;

  XdeltaBuilder({
    required this.originalFile,
    required this.modifiedFile,
    required this.outputFile,
  });

  Future<void> build() async {
    final binary = AppConfig.xdelta3Path;

    if (!await File(binary).exists()) {
      throw PatchException(
        'xdelta3 binary not found. Please re-download the full ZIP.',
      );
    }

    final args = [
      '-e', // encode (create patch)
      '-s', originalFile.path,
      modifiedFile.path,
      outputFile.path,
    ];

    final result = await Process.run(binary, args);

    if (result.exitCode != 0) {
      final err = (result.stderr as String).trim();
      throw PatchException('xdelta3 creation failed: $err');
    }
  }
}
