// SPDX-License-Identifier: GPL-3.0-or-later
// Ported from Final ROM (https://github.com/eon-com/final_rom) and
// UniPatcher (https://github.com/btimofeev/UniPatcher) — both GPL v3.
// Adapted for OpenROM by M5 Dev.
import 'dart:io';
import 'dart:typed_data';

import 'package:openrom_flutter/patcher/io_tuning.dart';

/// Patcher copy/CRC buffer size; defined centrally as [patchCopyBufferSize].
const int patchBufferSize = patchCopyBufferSize;

/// Copies [size] bytes from [from] to [to], starting at each file's current
/// position and writing sequentially. Stops early if the source runs out.
Future<void> copyBytes(RandomAccessFile from, RandomAccessFile to, int size) async {
  int remaining = size;
  while (remaining > 0) {
    final toRead = remaining > patchBufferSize ? patchBufferSize : remaining;
    final bytes = await from.read(toRead);
    if (bytes.isEmpty) break;
    await to.writeFrom(bytes);
    remaining -= bytes.length;
  }
}

/// Writes [size] copies of [value] to [to] at its current position.
Future<void> fillBytes(RandomAccessFile to, int size, int value) async {
  int remaining = size;
  final chunk = Uint8List(patchBufferSize)..fillRange(0, patchBufferSize, value);
  while (remaining > 0) {
    final toWrite = remaining > patchBufferSize ? patchBufferSize : remaining;
    await to.writeFrom(chunk, 0, toWrite);
    remaining -= toWrite;
  }
}

/// Streams the entire contents of [rom] (from its current position) into
/// [output] sequentially. Used by formats that patch a copy of the ROM
/// in place (PPF, APS-GBA) instead of building the output from scratch.
///
/// We copy through a write-mode output handle rather than `File.copy` so the
/// same handle can then be seeked and overwritten at arbitrary offsets without
/// reopening the file.
Future<void> copyWholeFile(RandomAccessFile rom, RandomAccessFile output) async {
  await rom.setPosition(0);
  while (true) {
    final bytes = await rom.read(patchBufferSize);
    if (bytes.isEmpty) break;
    await output.writeFrom(bytes);
  }
}
