// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'ips_builder.dart';

/// EarthBound Patch (EBP) builder — delegates to IPS builder.
class EbpBuilder {
  final File originalFile;
  final File modifiedFile;
  final File outputFile;

  EbpBuilder({
    required this.originalFile,
    required this.modifiedFile,
    required this.outputFile,
  });

  Future<void> build() async {
    final ips = IpsBuilder(
      originalFile: originalFile,
      modifiedFile: modifiedFile,
      outputFile: outputFile,
    );
    await ips.build();
  }
}
