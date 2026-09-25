// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'config.dart' as config;

const Map<String, String> supportedInput = {
  '.iso': 'ISO',
  '.bin': 'BIN',
  '.cue': 'CUE',
  '.gdi': 'GDI',
  '.cdi': 'CDI',
  '.img': 'IMG',
  '.ecm': 'ECM',
  '.chd': 'CHD',
  '.cso': 'CSO',
  '.zso': 'ZSO',
  '.rvz': 'RVZ',
  '.wia': 'WIA',
  '.wbfs': 'WBFS',
  '.wud': 'WUD',
  '.wux': 'WUX',
  '.nkit.iso': 'NKIT',
  '.gcz': 'GCZ',
  '.cci': 'CCI',
  '.zar': 'ZAR',
};

const Map<String, String> platformMap = {
  'ISO': 'ISO Image',
  'BIN': 'CD Image',
  'CUE': 'CD Cue Sheet',
  'GDI': 'Dreamcast GDI',
  'CDI': 'Dreamcast CDI',
  'IMG': 'Disk Image',
  'ECM': 'ECM Compressed',
  'CHD': 'CHD Archive',
  'CSO': 'Compressed ISO',
  'ZSO': 'Compressed ISO',
  'XISO': 'Xbox ISO',
  'CCI': 'Xbox 360 CCI',
  'ZAR': 'Xbox 360 ZAR',
  'RVZ': 'GameCube / Wii',
  'WIA': 'GameCube / Wii',
  'WBFS': 'Wii',
  'GCZ': 'GameCube / Wii',
  'WUD': 'Wii U',
  'WUX': 'Wii U',
  'NKIT': 'GameCube / Wii',
  'Saturn': 'Sega Saturn',
  'Sega CD': 'Sega CD / Mega-CD',
  'PC-Engine CD': 'PC-Engine CD / TurboGrafx-CD',
  'Neo Geo CD': 'Neo Geo CD',
};

const Map<String, String> formatColors = {
  'ISO': '#e94560',
  'BIN': '#f9a825',
  'CUE': '#f9a825',
  'GDI': '#9c27b0',
  'CDI': '#7b1fa2',
  'IMG': '#673ab7',
  'CHD': '#00bcd4',
  'CSO': '#4caf50',
  'ZSO': '#4caf50',
  'ECM': '#ff9800',
  'XISO': '#e91e63',
  'CCI': '#4caf50',
  'ZAR': '#388e3c',
  'RVZ': '#3f51b5',
  'WIA': '#5c6bc0',
  'WBFS': '#7986cb',
  'GCZ': '#9fa8da',
  'WUD': '#e65100',
  'WUX': '#ef6c00',
  'NKIT': '#1a237e',
  'UNKNOWN': '#7a8a9a',
  'Saturn': '#1565c0',
  'Sega CD': '#4a148c',
  'PC-Engine CD': '#bf360c',
  'Neo Geo CD': '#b71c1c',
};

const Map<String, List<String>> conversionMap = {
  'ISO': ['CHD', 'CSO', 'ECM', 'XISO', 'RVZ', 'NKIT'],
  'BIN': ['CHD', 'ECM'],
  'CUE': ['CHD'],
  'GDI': ['CHD'],
  'CDI': ['CHD'],
  'IMG': ['CHD'],
  'CHD': ['ISO', 'BIN/CUE'],
  'CSO': ['ISO'],
  'ZSO': ['ISO'],
  'ECM': ['ISO', 'BIN'],
  'XISO': ['Files'],
  'RVZ': ['ISO'],
  'WIA': ['ISO'],
  'WBFS': ['ISO'],
  'GCZ': ['ISO'],
  'WUD': ['ISO'],
  'WUX': ['ISO'],
  'NKIT': ['ISO'],
  'CCI': ['ISO'],
  'ZAR': ['ISO'],
};

const Map<String, String> commandTemplates = {
  'ISO->CHD': 'chdman createdvd -i "{in}" -o "{out}"',
  'ISO->CSO': 'maxcso "{in}" -o "{out}"',
  'ISO->ECM': 'ecm "{in}" "{out}"',
  'ISO->XISO': 'extract-xiso -r "{in}"',
  'ISO->RVZ': 'nodtool convert "{in}" "{out}"',
  'BIN->CHD': 'chdman createcd -i "{cue}" -o "{out}"',
  'BIN->ECM': 'ecm "{in}" "{out}"',
  'CUE->CHD': 'chdman createcd -i "{in}" -o "{out}"',
  'GDI->CHD': 'chdman createcd -i "{in}" -o "{out}"',
  'CDI->CHD': 'chdman createcd -i "{in}" -o "{out}"',
  'IMG->CHD': 'chdman createdvd -i "{in}" -o "{out}"',
  'CHD->ISO': 'chdman extractdvd -i "{in}" -o "{out}"',
  'CHD->BIN/CUE': 'chdman extractcd -i "{in}" -o "{out_cue}"',
  'CHD->BIN': 'chdman extractcd -i "{in}" -o "{out_cue}"',
  'CSO->ISO': 'maxcso --decompress "{in}" -o "{out}"',
  'ZSO->ISO': 'maxcso --decompress "{in}" -o "{out}"',
  'ECM->ISO': 'unecm "{in}" "{out}"',
  'ECM->BIN': 'unecm "{in}" "{out}"',
  'XISO->Files': 'extract-xiso -x "{in}" -d "{out}"',
  'RVZ->ISO': 'nodtool convert "{in}" "{out}"',
  'WIA->ISO': 'nodtool convert "{in}" "{out}"',
  'WBFS->ISO': 'nodtool convert "{in}" "{out}"',
  'GCZ->ISO': 'nodtool convert "{in}" "{out}"',
  'WUD->ISO': 'nkit convert -i "{in}" -o "{out}"',
  'WUX->ISO': 'nkit convert -i "{in}" -o "{out}"',
  'NKIT->ISO': 'nkit convert -i "{in}" -o "{out}"',
  'ISO->NKIT': 'nkit convert -i "{in}" -o "{out}"',
  'CCI->ISO': 'xgdtool --xiso "{in}" "{outdir}"',
  'ZAR->ISO': 'xgdtool --xiso "{in}" "{outdir}"',
};

// Magic bytes
final Uint8List chdMagic = Uint8List.fromList([0x4D, 0x43, 0x6F, 0x6D, 0x70, 0x72, 0x48, 0x44]); // MComprHD
final Uint8List ps2Magic = Uint8List.fromList('PLAYSTATION'.codeUnits);
final Uint8List ps1Magic = Uint8List.fromList('PlayStation'.codeUnits);
const int gcMagic = 0xC2339F3D;
const int wiiMagic = 0x5D1C9EA3;

final Uint8List saturnMagic1 = Uint8List.fromList('SEGA SEGASATURN'.codeUnits);
final Uint8List saturnMagic2 = Uint8List.fromList('SEGA SATURN '.codeUnits);
final Uint8List segacdMagic1 = Uint8List.fromList('SEGADISCSYSTEM'.codeUnits);
final Uint8List segacdMagic2 = Uint8List.fromList('SEGA_CD'.codeUnits);
final Uint8List pcecdMagic = Uint8List.fromList('PC Engine CD-ROM SYSTEM'.codeUnits);
final Uint8List neogeocdMagic = Uint8List.fromList('NEO-GEO CD'.codeUnits);

final Uint8List xboxMagic = Uint8List.fromList('MICROSOFT*XBOX*MEDIA'.codeUnits);
const int xboxOffset1 = 0x10000;
const int xboxOffset2 = 0x2090000;

String getExtension(String filename) {
  final nameLower = filename.toLowerCase();
  if (nameLower.endsWith('.nkit.iso')) {
    return 'nkit.iso';
  }
  final parts = nameLower.split('.');
  return parts.length > 1 ? parts.last : '';
}

String getOutputName(String inputFile, String newExt) {
  final cleanExt = newExt.startsWith('.') ? newExt.substring(1) : newExt;
  final String base;
  if (inputFile.toLowerCase().endsWith('.nkit.iso')) {
    base = inputFile.substring(0, inputFile.length - 9);
  } else {
    final idx = inputFile.lastIndexOf('.');
    base = idx != -1 ? inputFile.substring(0, idx) : inputFile;
  }
  if (base.toLowerCase().endsWith('.${cleanExt.toLowerCase()}')) {
    return base;
  }
  return '$base.$cleanExt';
}

String getBadgeColor(String fmt) {
  return formatColors[fmt.toUpperCase()] ?? formatColors['UNKNOWN']!;
}

List<String> getValidTargets(String fmt) {
  return conversionMap[fmt.toUpperCase()] ?? [];
}

String getCommandPreview(String fmt, String target, [String filename = 'game.iso']) {
  final key = '${fmt.toUpperCase()}->${target.toUpperCase()}';
  final template = commandTemplates[key];
  if (template == null) {
    return '$fmt -> $target';
  }
  final outName = getOutputName(filename, target.toLowerCase().replaceAll('/cue', ''));
  final idx = filename.lastIndexOf('.');
  final base = idx != -1 ? filename.substring(0, idx) : filename;
  final cueName = '$base.cue';

  return template
      .replaceAll('{in}', filename)
      .replaceAll('{out}', outName)
      .replaceAll('{cue}', cueName)
      .replaceAll('{out_cue}', cueName);
}

Map<String, dynamic> detectFile(String filepath) {
  final file = File(filepath);
  if (!file.existsSync()) {
    return {'error': 'File not found: $filepath'};
  }

  final name = p.basename(filepath);
  final nameLower = name.toLowerCase();
  final String ext;
  if (nameLower.endsWith('.nkit.iso')) {
    ext = '.nkit.iso';
  } else {
    ext = p.extension(nameLower);
  }

  final size = file.lengthSync();
  final fmt = supportedInput[ext] ?? 'UNKNOWN';
  final needsEcm = (fmt == 'ECM');

  final header = _readHeader(filepath, 0x210000);
  final plat = _guessPlatform(filepath, fmt, size, header);
  final chdType = (fmt == 'CHD') ? _readChdType(filepath) : null;

  final result = <String, dynamic>{
    'format': fmt,
    'platform': plat,
    'size_bytes': size,
    'size_str': _humanSize(size),
    'needs_ecm_decode': needsEcm,
    'paired_cue': null,
    'paired_bin': null,
    'chd_type': chdType,
    'valid_targets': getValidTargets(fmt),
    'badge_color': getBadgeColor(fmt),
  };

  if (fmt == 'BIN') {
    result['paired_cue'] = _findPair(filepath, '.cue');
  } else if (fmt == 'CUE') {
    result['paired_bin'] = _findPair(filepath, '.bin');
  }

  return result;
}

List<Map<String, dynamic>> detectFolder(String folderPath) {
  final dir = Directory(folderPath);
  final results = <Map<String, dynamic>>[];
  if (!dir.existsSync()) return results;

  final entries = dir.listSync();
  for (final entry in entries) {
    if (entry is File) {
      final fname = p.basename(entry.path);
      final ext = '.${getExtension(fname)}';
      if (supportedInput.containsKey(ext)) {
        final info = detectFile(entry.path);
        info['filepath'] = entry.path;
        info['filename'] = fname;
        results.add(info);
      }
    }
  }
  return results;
}

String getChdmanPath() => config.getToolPath('chdman');

Uint8List _readHeader(String filepath, int size) {
  try {
    final file = File(filepath);
    final raf = file.openSync(mode: FileMode.read);
    final bytes = raf.readSync(size);
    raf.closeSync();
    return bytes;
  } catch (_) {
    return Uint8List(0);
  }
}

String _guessPlatform(String filepath, String fmt, int size, Uint8List header) {
  if (fmt == 'CCI') return 'Xbox 360';
  if (fmt == 'ZAR') return 'Xbox 360';
  if (fmt == 'GDI') return 'Dreamcast';
  if (fmt == 'CDI') return 'Dreamcast';
  if (fmt == 'CSO' || fmt == 'ZSO') {
    return (size < 2 * 1024 * 1024 * 1024) ? 'PSP' : 'PSP / PS2';
  }
  if (fmt == 'XISO') return 'Xbox';

  if (fmt == 'ISO' || fmt == 'BIN' || fmt == 'IMG' || fmt == 'CUE') {
    if (fmt == 'ISO' || fmt == 'IMG') {
      if (_headerHasXboxMagic(header) || _fileHasXboxMagicSlow(filepath)) {
        return 'Xbox';
      }
    }

    if ((fmt == 'ISO' || fmt == 'IMG') && _headerHasPspMagic(header)) {
      return 'PSP';
    }

    if ((fmt == 'ISO' || fmt == 'IMG') && _headerHasGcMagic(header)) {
      return 'GameCube';
    }

    if ((fmt == 'ISO' || fmt == 'IMG') && _headerHasWiiMagic(header)) {
      return 'Wii';
    }

    if (_headerHasSaturnMagic(header)) return 'Saturn';
    if (_headerHasSegacdMagic(header)) return 'Sega CD';
    if (_headerHasPcecdMagic(header)) return 'PC-Engine CD';
    if (_headerHasNeogeocdMagic(header)) return 'Neo Geo CD';
    if (_headerHasPs2Magic(header)) return 'PS2';
    if (_headerHasPs1Magic(header)) return 'PS1';

    final mb = size / (1024 * 1024);
    if (mb < 700) {
      return 'PS1';
    } else if (mb < 8500) {
      return 'PS2 / GC';
    } else {
      return 'PS2 / Xbox';
    }
  }

  return platformMap[fmt] ?? 'ROM File';
}

bool _containsSublist(Uint8List list, Uint8List sublist) {
  if (sublist.isEmpty || list.length < sublist.length) return false;
  for (int i = 0; i <= list.length - sublist.length; i++) {
    bool match = true;
    for (int j = 0; j < sublist.length; j++) {
      if (list[i + j] != sublist[j]) {
        match = false;
        break;
      }
    }
    if (match) return true;
  }
  return false;
}

bool _sublistEquals(Uint8List list, int offset, Uint8List sublist) {
  if (offset < 0 || offset + sublist.length > list.length) return false;
  for (int i = 0; i < sublist.length; i++) {
    if (list[offset + i] != sublist[i]) return false;
  }
  return true;
}

bool _headerHasXboxMagic(Uint8List header) {
  return _sublistEquals(header, xboxOffset1, xboxMagic);
}

bool _fileHasXboxMagicSlow(String filepath) {
  try {
    final file = File(filepath);
    final raf = file.openSync(mode: FileMode.read);
    raf.setPositionSync(xboxOffset2);
    final bytes = raf.readSync(xboxMagic.length);
    raf.closeSync();
    return _sublistEquals(bytes, 0, xboxMagic);
  } catch (_) {
    return false;
  }
}

bool _headerHasPspMagic(Uint8List header) {
  final sliceLen = header.length < 65536 ? header.length : 65536;
  final slice = Uint8List.sublistView(header, 0, sliceLen);
  return _containsSublist(slice, Uint8List.fromList('PSP_GAME'.codeUnits)) ||
      _containsSublist(slice, Uint8List.fromList('UMD_DATA'.codeUnits));
}

bool _headerHasGcMagic(Uint8List header) {
  if (header.length >= 0x20) {
    final bd = ByteData.sublistView(header);
    final word = bd.getUint32(0x1C, Endian.big);
    return word == gcMagic;
  }
  return false;
}

bool _headerHasWiiMagic(Uint8List header) {
  if (header.length >= 0x1C) {
    final bd = ByteData.sublistView(header);
    final word = bd.getUint32(0x18, Endian.big);
    return word == wiiMagic;
  }
  return false;
}

bool _headerHasPs2Magic(Uint8List header) {
  if (header.length >= 0x8800) {
    final slice = Uint8List.sublistView(header, 0x8000, 0x8800);
    return _containsSublist(slice, ps2Magic);
  }
  return false;
}

bool _headerHasPs1Magic(Uint8List header) {
  final sliceLen = header.length < 65536 ? header.length : 65536;
  final slice = Uint8List.sublistView(header, 0, sliceLen);
  return _containsSublist(slice, ps1Magic);
}

bool _headerHasSaturnMagic(Uint8List header) {
  return _sublistEquals(header, 0x10, saturnMagic1) ||
      _sublistEquals(header, 0x00, saturnMagic2);
}

bool _headerHasSegacdMagic(Uint8List header) {
  return _sublistEquals(header, 0x10, segacdMagic1) ||
      _sublistEquals(header, 0x00, segacdMagic2);
}

bool _headerHasPcecdMagic(Uint8List header) {
  final sliceLen = header.length < 2048 ? header.length : 2048;
  final slice = Uint8List.sublistView(header, 0, sliceLen);
  return _containsSublist(slice, pcecdMagic);
}

bool _headerHasNeogeocdMagic(Uint8List header) {
  final sliceLen = header.length < 0x800 ? header.length : 0x800;
  final slice = Uint8List.sublistView(header, 0, sliceLen);
  return _containsSublist(slice, neogeocdMagic);
}

String _readChdType(String filepath) {
  try {
    final file = File(filepath);
    final raf = file.openSync(mode: FileMode.read);
    final raw = raf.readSync(128);
    raf.closeSync();

    if (raw.length < 16 || !_sublistEquals(raw, 0, chdMagic)) {
      return _chdTypeBySize(file.lengthSync());
    }

    final bd = ByteData.sublistView(raw);
    final version = bd.getUint32(12, Endian.big);

    if (version == 5 && raw.length >= 64) {
      final unitbytes = bd.getUint32(60, Endian.big);
      if (unitbytes == 2448) {
        return 'cd';
      } else if (unitbytes == 512 || unitbytes == 2048 || unitbytes == 4096) {
        return 'dvd';
      }
    } else if (version == 4 && raw.length >= 108) {
      final flags = bd.getUint32(16, Endian.big);
      if ((flags & 0x2) != 0) {
        return 'cd';
      }
      return 'dvd';
    }

    return _chdTypeBySize(file.lengthSync());
  } catch (_) {
    try {
      return _chdTypeBySize(File(filepath).lengthSync());
    } catch (_) {
      return 'cd';
    }
  }
}

String _chdTypeBySize(int size) {
  final mb = size / (1024 * 1024);
  return mb < 900 ? 'cd' : 'dvd';
}

String? _findPair(String filepath, String targetExt) {
  final idx = filepath.lastIndexOf('.');
  final base = idx != -1 ? filepath.substring(0, idx) : filepath;
  final candidate = base + (targetExt.startsWith('.') ? targetExt : '.$targetExt');
  return File(candidate).existsSync() ? candidate : null;
}

String _humanSize(int size) {
  double doubleSize = size.toDouble();
  for (final unit in ['B', 'KB', 'MB', 'GB']) {
    if (doubleSize < 1024) {
      return '${doubleSize.toStringAsFixed(1)} $unit';
    }
    doubleSize /= 1024;
  }
  return '${doubleSize.toStringAsFixed(1)} TB';
}
