// SPDX-License-Identifier: GPL-3.0-or-later
// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'checksums.dart';
import 'patcher.dart';

/// Stable identity information for a ROM used to build a patch.
class RomIdentity {
  final String fileName;
  final int sizeBytes;
  final String crc32;
  final String sha256;

  const RomIdentity({
    required this.fileName,
    required this.sizeBytes,
    required this.crc32,
    required this.sha256,
  });

  static Future<RomIdentity> fromFile(File file) async {
    final bytes = await file.readAsBytes();
    return RomIdentity(
      fileName: file.uri.pathSegments.last,
      sizeBytes: bytes.length,
      crc32: crc32Bytes(bytes).toRadixString(16).padLeft(8, '0'),
      sha256: sha256.convert(bytes).toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'fileName': fileName,
        'sizeBytes': sizeBytes,
        'crc32': crc32,
        'sha256': sha256,
      };

  factory RomIdentity.fromJson(Map<String, dynamic> json) => RomIdentity(
        fileName: json['fileName'] as String? ?? '',
        sizeBytes: json['sizeBytes'] as int,
        crc32: json['crc32'] as String,
        sha256: json['sha256'] as String,
      );
}

/// Sidecar metadata written next to generated patches.
///
/// The sidecar keeps the original patch bytes compatible with existing tools,
/// while making the expected source ROM explicit for formats such as IPS and
/// xdelta that do not carry a source identity themselves.
class PatchManifest {
  static const int schemaVersion = 1;

  final String format;
  final RomIdentity baseRom;
  final RomIdentity targetRom;

  const PatchManifest({
    required this.format,
    required this.baseRom,
    required this.targetRom,
  });

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'format': format,
        'baseRom': baseRom.toJson(),
        'targetRom': targetRom.toJson(),
      };

  factory PatchManifest.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] != schemaVersion) {
      throw PatchException('Unsupported patch manifest schema.');
    }
    return PatchManifest(
      format: json['format'] as String? ?? 'unknown',
      baseRom: RomIdentity.fromJson(json['baseRom'] as Map<String, dynamic>),
      targetRom:
          RomIdentity.fromJson(json['targetRom'] as Map<String, dynamic>),
    );
  }

  static String sidecarPath(String patchPath) => '$patchPath.json';

  static Future<PatchManifest?> readForPatch(File patchFile) async {
    final sidecar = File(sidecarPath(patchFile.path));
    if (!await sidecar.exists()) return null;

    try {
      final decoded = jsonDecode(await sidecar.readAsString());
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Manifest root must be an object.');
      }
      return PatchManifest.fromJson(decoded);
    } on PatchException {
      rethrow;
    } catch (e) {
      throw PatchException('Invalid patch manifest: $e');
    }
  }

  Future<void> writeForPatch(File patchFile) async {
    final sidecar = File(sidecarPath(patchFile.path));
    final contents = const JsonEncoder.withIndent('  ').convert(toJson());
    await sidecar.writeAsString('$contents\n');
  }

  Future<void> validateBase(File romFile) async {
    if (!await romFile.exists()) {
      throw PatchException('Base ROM not found: ${romFile.path}');
    }

    final actual = await RomIdentity.fromFile(romFile);
    if (actual.sizeBytes != baseRom.sizeBytes ||
        actual.sha256.toLowerCase() != baseRom.sha256.toLowerCase()) {
      throw PatchException(
        'Base ROM mismatch. Expected ${baseRom.fileName} '
        '(size ${baseRom.sizeBytes}, SHA-256 ${baseRom.sha256}), '
        'but received ${actual.fileName} '
        '(size ${actual.sizeBytes}, SHA-256 ${actual.sha256}).',
      );
    }
  }
}
