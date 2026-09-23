// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

const int ipbinSize = 2048;

class IpbinField {
  final int offset;
  final int length;
  final String name;

  const IpbinField(this.offset, this.length, this.name);
}

const List<IpbinField> ipbinFields = [
  IpbinField(0x00, 16, 'hardware_id'),
  IpbinField(0x10, 16, 'maker_id'),
  IpbinField(0x20, 10, 'product_number'),
  IpbinField(0x2A, 6, 'product_version'),
  IpbinField(0x30, 8, 'release_date'),
  IpbinField(0x38, 8, 'boot_filename'),
  IpbinField(0x40, 16, 'software_type'),
  IpbinField(0x50, 8, 'region_code'),
  IpbinField(0x58, 8, 'peripherals'),
  IpbinField(0x60, 16, 'product_name'),
  IpbinField(0x70, 16, 'product_name_2'),
];

const Map<String, String> regionFlags = {
  'J': 'Japan',
  'U': 'USA',
  'E': 'Europe',
};

Map<String, dynamic> readIpbin(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    throw FileSystemException('IP.BIN not found: $path', path);
  }

  final data = file.readAsBytesSync();
  if (data.length < ipbinSize) {
    throw FormatException(
        'File too small to be IP.BIN: ${data.length} bytes (need $ipbinSize)');
  }

  final hardwareIdBytes = data.sublist(0x00, 0x10);
  final hardwareId = ascii.decode(hardwareIdBytes, allowInvalid: true).trim();
  if (!hardwareId.contains('SEGA')) {
    throw FormatException('Not a valid Dreamcast IP.BIN (hardware_id: "$hardwareId")');
  }

  final result = <String, dynamic>{
    '_raw': Uint8List.fromList(data.sublist(0, ipbinSize)),
    '_path': path,
  };

  for (final field in ipbinFields) {
    final raw = data.sublist(field.offset, field.offset + field.length);
    String decoded;
    if (field.name == 'product_name' || field.name == 'product_name_2') {
      try {
        decoded = latin1.decode(raw);
      } catch (_) {
        decoded = ascii.decode(raw, allowInvalid: true);
      }
    } else {
      decoded = ascii.decode(raw, allowInvalid: true);
    }
    result[field.name] = decoded.trimRight();
  }

  final regionRaw = result['region_code'] as String? ?? '';
  final regions = <String>[];
  for (final c in ['J', 'U', 'E']) {
    if (regionRaw.contains(c)) {
      regions.add(regionFlags[c]!);
    }
  }
  result['regions'] = regions;

  return result;
}

void writeIpbin(Map<String, dynamic> fields, String outputPath) {
  final raw = fields['_raw'] as Uint8List?;
  if (raw == null || raw.length < ipbinSize) {
    throw ArgumentError('fields must contain valid _raw Uint8List buffer of 2048 bytes');
  }

  final data = Uint8List.fromList(raw);

  for (final field in ipbinFields) {
    if (!fields.containsKey(field.name) || field.name.startsWith('_')) {
      continue;
    }
    final val = fields[field.name] as String? ?? '';
    List<int> encoded;
    try {
      encoded = ascii.encode(val);
    } catch (_) {
      encoded = latin1.encode(val);
    }

    final padded = List<int>.filled(field.length, 0x20);
    for (int i = 0; i < field.length && i < encoded.length; i++) {
      padded[i] = encoded[i];
    }

    for (int i = 0; i < field.length; i++) {
      data[field.offset + i] = padded[i];
    }
  }

  if (fields.containsKey('regions')) {
    final regionsList = (fields['regions'] as List).cast<String>();
    var regionStr = '';
    regionFlags.forEach((code, name) {
      if (regionsList.contains(name)) {
        regionStr += code;
      }
    });

    final regionEncoded = ascii.encode(regionStr);
    final padded = List<int>.filled(8, 0x20);
    for (int i = 0; i < 8 && i < regionEncoded.length; i++) {
      padded[i] = regionEncoded[i];
    }
    for (int i = 0; i < 8; i++) {
      data[0x50 + i] = padded[i];
    }
  }

  File(outputPath).writeAsBytesSync(data);
}

Map<String, dynamic> setRegionFree(Map<String, dynamic> fields) {
  fields['regions'] = ['Japan', 'USA', 'Europe'];
  return fields;
}

Map<String, dynamic> setVgaEnabled(Map<String, dynamic> fields) {
  final perip = fields['peripherals'] as String? ?? '00000000';
  int flags = 0;
  try {
    flags = int.parse(perip.trim(), radix: 16);
  } catch (_) {
    flags = 0;
  }
  flags |= (1 << 4);
  fields['peripherals'] = flags.toRadixString(16).toUpperCase().padLeft(8, '0');
  return fields;
}
