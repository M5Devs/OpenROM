// SPDX-License-Identifier: GPL-3.0-or-later
// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:io';

import 'package:openrom_core/openrom_core.dart' as core;

import 'patcher.dart';

/// DCP (Universal Dreamcast Patcher) patch builder.
class DcpBuilder {
  final Directory originalDir;
  final Directory modifiedDir;
  final File outputFile;
  final bool useXdelta;
  final void Function(String msg)? onLog;
  final void Function(double pct)? onProgress;

  DcpBuilder({
    required this.originalDir,
    required this.modifiedDir,
    required this.outputFile,
    this.useXdelta = true,
    this.onLog,
    this.onProgress,
  });

  Future<void> build() async {
    final builder = core.DcpBuilder(
      originalDir: originalDir,
      modifiedDir: modifiedDir,
      outputFile: outputFile,
      useXdelta: useXdelta,
      onLog: onLog,
      onProgress: onProgress,
    );

    try {
      await builder.build();
    } on FormatException catch (e) {
      throw PatchException(e.message);
    } catch (e) {
      if (e is PatchException) rethrow;
      throw PatchException(e.toString());
    }
  }
}
