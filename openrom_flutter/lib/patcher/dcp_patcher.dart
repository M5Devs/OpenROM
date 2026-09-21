// SPDX-License-Identifier: GPL-3.0-or-later
// M5 Dev — Dreamcast DCP patch applier
// Delegates to openrom-core --dcp via CoreBridge subprocess.

import 'dart:io';
import 'package:path/path.dart' as p;
import '../services/core_bridge.dart';
import 'patcher.dart';

/// DCP (Dreamcast Patch Container) applier.
/// DCP is a ZIP archive containing modified disc files and optional xdelta diffs.
/// Delegates to openrom-core --dcp for all disc manipulation.
class DcpPatcher {
  final String dcpPath;
  final String discDir;
  final String outputDir;
  final bool ignoreChecksum;

  DcpPatcher({
    required this.dcpPath,
    required this.discDir,
    required this.outputDir,
    this.ignoreChecksum = false,
  });

  Future<DcpPatchResult> apply() async {
    final args = [
      '--dcp', dcpPath,
      '--disc-dir', discDir,
      '--output', outputDir,
      '--json',
    ];
    if (ignoreChecksum) args.add('--ignore-checksum');

    final result = await CoreBridge.runCore(args);

    if (result.exitCode == 0) {
      return DcpPatchResult(
        success: true,
        log: result.stdout,
      );
    } else {
      throw PatchException('DCP patch failed:\n${result.stderr}');
    }
  }
}

class DcpPatchResult {
  final bool success;
  final String log;
  const DcpPatchResult({required this.success, required this.log});
}
