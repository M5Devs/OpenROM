// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3
//
// Native, pure-Dart MAME / Arcade ROM auditor.
//
// Parses MAME XML (and Logiqx DAT) set definitions with an event-based
// streaming decoder so multi-hundred-megabyte `mame.xml` files never enter
// memory as a DOM tree, then audits a folder of arcade ZIP archives in place
// by reading each archive's central directory. Nothing here shells out to an
// external binary.

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart' show InputFileStream;
import 'package:path/path.dart' as p;
import 'package:xml/xml_events.dart';

// ── DAT model ────────────────────────────────────────────────────────────────

/// A single ROM chip entry inside a machine set.
class MameRom {
  /// File name as declared in the DAT (may contain sub-directory segments).
  final String name;

  /// Uncompressed size in bytes (`0` when the DAT omits it).
  final int size;

  /// Lower-case, zero-padded CRC-32 (`''` when the DAT omits it).
  final String crc;

  /// Lower-case SHA-1 (`''` when the DAT omits it).
  final String sha1;

  /// Merge hint: the name of the ROM this entry is merged from, or `null`.
  final String? merge;

  /// Region the chip belongs to (e.g. `maincpu`, `gfx1`), or `null`.
  final String? region;

  const MameRom({
    required this.name,
    this.size = 0,
    this.crc = '',
    this.sha1 = '',
    this.merge,
    this.region,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'size': size,
        'crc': crc,
        'sha1': sha1,
        if (merge != null) 'merge': merge,
        if (region != null) 'region': region,
      };
}

/// A CHD disk image referenced by a machine.
class MameDisk {
  final String name;
  final String sha1;
  final String? merge;

  const MameDisk({
    required this.name,
    this.sha1 = '',
    this.merge,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'sha1': sha1,
        if (merge != null) 'merge': merge,
      };
}

/// A single machine (game / BIOS / device) set from the DAT.
class MameMachine {
  /// Machine slug, e.g. `mslug`.
  final String name;

  /// Human-readable title, e.g. `Metal Slug - Super Vehicle-001`. Filled from
  /// the `<description>` child element once the parser reaches it.
  String description;

  /// Parent machine slug for clones (`cloneof`), or `null`.
  final String? cloneOf;

  /// BIOS / parent set this machine borrows ROMs from (`romof`), or `null`.
  final String? romOf;

  /// `true` when the machine is a BIOS or device set (`isbios` / `isdevice`).
  final bool isBios;
  final bool isDevice;

  /// ROM chips declared for this set (grown as the parser walks `<rom>` tags).
  final List<MameRom> roms = [];

  /// CHD disks declared for this set.
  final List<MameDisk> disks = [];

  MameMachine({
    required this.name,
    required this.description,
    this.cloneOf,
    this.romOf,
    this.isBios = false,
    this.isDevice = false,
  });

  bool get isClone => cloneOf != null && cloneOf!.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        if (cloneOf != null) 'cloneof': cloneOf,
        if (romOf != null) 'romof': romOf,
        'isbios': isBios,
        'isdevice': isDevice,
        'roms': roms.map((r) => r.toJson()).toList(),
        'disks': disks.map((d) => d.toJson()).toList(),
      };
}

/// A parsed DAT: header metadata plus every machine definition.
class MameDat {
  final String name;
  final String description;
  final String version;

  /// Machines keyed by slug.
  final Map<String, MameMachine> machines;

  MameDat({
    required this.name,
    required this.description,
    required this.version,
    required this.machines,
  });

  int get machineCount => machines.length;

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'version': version,
        'machine_count': machines.length,
      };
}

// ── Streaming parser ─────────────────────────────────────────────────────────

/// Parses a MAME XML or Logiqx DAT file into a [MameDat] using an event-based
/// streaming decoder.
///
/// Only the current machine's chip list is buffered; each completed machine is
/// folded into [MameDat.machines] and the element state is reused, so peak
/// memory tracks the largest single set rather than the whole file.
Future<MameDat> parseMameDat(
  String datPath, {
  void Function(int machines)? onProgress,
}) async {
  final file = File(datPath);
  if (!file.existsSync()) {
    throw ArgumentError('DAT file not found: $datPath');
  }

  final machines = <String, MameMachine>{};

  String datName = '';
  String datDescription = '';
  String datVersion = '';

  // `header` and `machine`/`game` reuse the same tag names (`name`,
  // `description`), so we track which subtree we are inside instead of a
  // single "current tag" variable that would cross the streams.
  var inHeader = false;
  String? headerTag;
  var inMachineDescription = false;
  MameMachine? current;
  var machineIndex = 0;

  final events = file
      .openRead()
      .transform(utf8.decoder)
      .transform(XmlEventDecoder())
      .expand((e) => e);

  await for (final event in events) {
    if (event is XmlStartElementEvent) {
      switch (event.name) {
        case 'header':
          inHeader = true;
          break;
        case 'machine':
        case 'game':
          // Logiqx DATs use `<game>`; MAME uses `<machine>`. Treat both.
          current = _machineFromEvent(event);
          break;
        case 'description':
          if (inHeader) {
            headerTag = 'description';
          } else if (current != null) {
            inMachineDescription = true;
          }
          break;
        case 'rom':
          if (current != null) {
            current.roms.add(_romFromEvent(event));
          }
          break;
        case 'disk':
          if (current != null) {
            current.disks.add(_diskFromEvent(event));
          }
          break;
        default:
          if (inHeader) headerTag = event.name;
          break;
      }
    } else if (event is XmlTextEvent) {
      final text = event.value.trim();
      if (text.isEmpty) continue;
      if (inMachineDescription && current != null) {
        if (current.description.isEmpty) current.description = text;
      } else if (inHeader && headerTag != null) {
        switch (headerTag) {
          case 'name':
            if (datName.isEmpty) datName = text;
            break;
          case 'description':
            if (datDescription.isEmpty) datDescription = text;
            break;
          case 'version':
            if (datVersion.isEmpty) datVersion = text;
            break;
        }
      }
    } else if (event is XmlEndElementEvent) {
      switch (event.name) {
        case 'header':
          inHeader = false;
          headerTag = null;
          break;
        case 'description':
          if (inMachineDescription) {
            inMachineDescription = false;
          } else {
            headerTag = null;
          }
          break;
        case 'machine':
        case 'game':
          final machine = current;
          if (machine != null && machine.name.isNotEmpty) {
            machines[machine.name] = machine;
            machineIndex++;
            if (onProgress != null && machineIndex % 1000 == 0) {
              onProgress(machineIndex);
            }
          }
          current = null;
          break;
      }
    }
  }

  if (datName.isEmpty) datName = p.basenameWithoutExtension(datPath);
  if (datDescription.isEmpty) datDescription = datName;

  if (onProgress != null && machineIndex > 0) {
    onProgress(machineIndex);
  }

  return MameDat(
    name: datName,
    description: datDescription,
    version: datVersion,
    machines: machines,
  );
}

MameMachine _machineFromEvent(XmlStartElementEvent event) {
  var name = '';
  var description = '';
  String? cloneOf;
  String? romOf;
  var isBios = false;
  var isDevice = false;

  for (final attr in event.attributes) {
    switch (attr.name) {
      case 'name':
        name = attr.value;
        break;
      case 'cloneof':
        cloneOf = _nullIfEmpty(attr.value);
        break;
      case 'romof':
        romOf = _nullIfEmpty(attr.value);
        break;
      case 'isbios':
        isBios = attr.value == 'yes';
        break;
      case 'isdevice':
        isDevice = attr.value == 'yes';
        break;
    }
  }

  return MameMachine(
    name: name,
    description: description,
    cloneOf: cloneOf,
    romOf: romOf,
    isBios: isBios,
    isDevice: isDevice,
  );
}

MameRom _romFromEvent(XmlStartElementEvent event) {
  var name = '';
  var size = 0;
  var crc = '';
  var sha1 = '';
  String? merge;
  String? region;

  for (final attr in event.attributes) {
    switch (attr.name) {
      case 'name':
        name = attr.value;
        break;
      case 'size':
        size = int.tryParse(attr.value) ?? 0;
        break;
      case 'crc':
        crc = _normaliseCrc(attr.value);
        break;
      case 'sha1':
        sha1 = attr.value.trim().toLowerCase();
        break;
      case 'merge':
        merge = _nullIfEmpty(attr.value);
        break;
      case 'region':
        region = _nullIfEmpty(attr.value);
        break;
    }
  }

  return MameRom(
    name: name,
    size: size,
    crc: crc,
    sha1: sha1,
    merge: merge,
    region: region,
  );
}

MameDisk _diskFromEvent(XmlStartElementEvent event) {
  var name = '';
  var sha1 = '';
  String? merge;

  for (final attr in event.attributes) {
    switch (attr.name) {
      case 'name':
        name = attr.value;
        break;
      case 'sha1':
        sha1 = attr.value.trim().toLowerCase();
        break;
      case 'merge':
        merge = _nullIfEmpty(attr.value);
        break;
    }
  }

  return MameDisk(name: name, sha1: sha1, merge: merge);
}

String? _nullIfEmpty(String value) {
  final v = value.trim();
  return v.isEmpty ? null : v;
}

/// Normalises a CRC to 8 lower-case hex characters. MAME DATs sometimes write
/// CRCs without leading zeros (e.g. `0` or `a1b2c3`), so pad to width 8.
String _normaliseCrc(String value) {
  final v = value.trim().toLowerCase();
  if (v.isEmpty) return '';
  if (v.length >= 8) return v;
  return v.padLeft(8, '0');
}

// ── Audit model ──────────────────────────────────────────────────────────────

/// Audit verdict for a single machine.
enum MameAuditStatus {
  /// All ROMs (and required BIOS / parent / CHD) present and matching.
  complete,

  /// ROMs complete, but a required BIOS zip (e.g. `neogeo.zip`) is absent.
  missingBios,

  /// A clone is missing the parent files it borrows in a split set.
  missingParent,

  /// Specific chip ROMs are missing or CRC-mismatched inside the zip.
  incomplete,

  /// The zip is complete, but an associated CHD image is absent.
  missingChd,

  /// The machine has no zip at all in the folder.
  missing,

  /// The zip exists but could not be read (corrupt archive).
  error,
}

extension MameAuditStatusX on MameAuditStatus {
  /// Stable machine-readable slug for JSON consumers.
  String get slug => switch (this) {
        MameAuditStatus.complete => 'complete',
        MameAuditStatus.missingBios => 'missing_bios',
        MameAuditStatus.missingParent => 'missing_parent',
        MameAuditStatus.incomplete => 'incomplete',
        MameAuditStatus.missingChd => 'missing_chd',
        MameAuditStatus.missing => 'missing',
        MameAuditStatus.error => 'error',
      };

  /// Emoji + label for human output.
  String get label => switch (this) {
        MameAuditStatus.complete => '🟢 Playable / Complete',
        MameAuditStatus.missingBios => '🟡 Missing BIOS',
        MameAuditStatus.missingParent => '🟡 Missing Parent',
        MameAuditStatus.incomplete => '🔴 Incomplete',
        MameAuditStatus.missingChd => '💽 Missing CHD',
        MameAuditStatus.missing => '🔴 Missing Set',
        MameAuditStatus.error => '⚠️ Unreadable',
      };
}

/// A single missing / mismatched chip or disk found during an audit.
class MameMissingEntry {
  /// `rom` or `disk`.
  final String kind;
  final String name;
  final int expectedSize;

  /// Expected CRC (ROMs only); `''` when unknown.
  final String expectedCrc;

  /// `missing` or `crc_mismatch` (ROMs) / `missing` (disks).
  final String reason;

  /// Actual CRC when the file was present but mismatched.
  final String actualCrc;

  /// Where the required file was expected (for BIOS/parent borrows).
  final String? fromSet;

  const MameMissingEntry({
    required this.kind,
    required this.name,
    this.expectedSize = 0,
    this.expectedCrc = '',
    this.reason = 'missing',
    this.actualCrc = '',
    this.fromSet,
  });

  Map<String, dynamic> toJson() => {
        'kind': kind,
        'name': name,
        'expected_size': expectedSize,
        'expected_crc': expectedCrc,
        'reason': reason,
        if (actualCrc.isNotEmpty) 'actual_crc': actualCrc,
        if (fromSet != null) 'from_set': fromSet,
      };
}

/// The result of auditing one machine against the folder.
class MameAuditResult {
  final String name;
  final String description;
  final MameAuditStatus status;

  /// Human-readable one-line explanation of the verdict.
  final String detail;

  /// Missing / mismatched ROM chips.
  final List<MameMissingEntry> missingRoms;

  /// Missing / mismatched CHD disks.
  final List<MameMissingEntry> missingDisks;

  /// BIOS zips required but absent (e.g. `neogeo`).
  final List<String> missingBios;

  /// Parent machine slug required but absent (for split clones).
  final List<String> missingParents;

  /// ROMs that were checked and matched.
  final int romsChecked;
  final int romsPresent;

  /// Disks that were checked and matched.
  final int disksChecked;
  final int disksPresent;

  final bool isClone;
  final bool isBios;

  const MameAuditResult({
    required this.name,
    required this.description,
    required this.status,
    required this.detail,
    this.missingRoms = const [],
    this.missingDisks = const [],
    this.missingBios = const [],
    this.missingParents = const [],
    this.romsChecked = 0,
    this.romsPresent = 0,
    this.disksChecked = 0,
    this.disksPresent = 0,
    this.isClone = false,
    this.isBios = false,
  });

  bool get isComplete => status == MameAuditStatus.complete;

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'status': status.slug,
        'status_label': status.label,
        'detail': detail,
        'is_clone': isClone,
        'is_bios': isBios,
        'roms_checked': romsChecked,
        'roms_present': romsPresent,
        'disks_checked': disksChecked,
        'disks_present': disksPresent,
        if (missingBios.isNotEmpty) 'missing_bios': missingBios,
        if (missingParents.isNotEmpty) 'missing_parents': missingParents,
        if (missingRoms.isNotEmpty)
          'missing_roms': missingRoms.map((m) => m.toJson()).toList(),
        if (missingDisks.isNotEmpty)
          'missing_disks': missingDisks.map((m) => m.toJson()).toList(),
      };
}

/// Aggregate health of a whole collection.
class MameAuditReport {
  final String datName;
  final String folder;

  /// Every audited machine, in DAT order.
  final List<MameAuditResult> results;

  /// Machines skipped because they are BIOS/device-only helper sets.
  final int skippedDevices;

  final DateTime generatedAt;

  MameAuditReport({
    required this.datName,
    required this.folder,
    required this.results,
    this.skippedDevices = 0,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  int get total => results.length;

  int countOf(MameAuditStatus status) =>
      results.where((r) => r.status == status).length;

  int get completeCount => countOf(MameAuditStatus.complete);
  int get missingBiosCount => countOf(MameAuditStatus.missingBios);
  int get missingParentCount => countOf(MameAuditStatus.missingParent);
  int get incompleteCount => countOf(MameAuditStatus.incomplete);
  int get missingChdCount => countOf(MameAuditStatus.missingChd);
  int get missingCount => countOf(MameAuditStatus.missing);
  int get errorCount => countOf(MameAuditStatus.error);

  /// Library health as a percentage of machines that are playable.
  double get healthPercent => total == 0 ? 0 : completeCount / total * 100.0;

  Map<String, dynamic> toJson() => {
        'dat': datName,
        'folder': folder,
        'generated_at': generatedAt.toIso8601String(),
        'total_games': total,
        'skipped_devices': skippedDevices,
        'complete': completeCount,
        'missing_bios': missingBiosCount,
        'missing_parent': missingParentCount,
        'incomplete': incompleteCount,
        'missing_chd': missingChdCount,
        'missing_set': missingCount,
        'errors': errorCount,
        'health_percent': double.parse(healthPercent.toStringAsFixed(1)),
        'games': results.map((r) => r.toJson()).toList(),
      };
}

// ── Archive scanning (central-directory only) ────────────────────────────────

/// Metadata for one entry inside a ZIP, read from the central directory
/// without decompressing the payload.
class ZipEntryInfo {
  final String name;
  final int size;
  final String crc;

  const ZipEntryInfo({
    required this.name,
    required this.size,
    required this.crc,
  });
}

/// Reads the central directory of [zipPath] and returns entry metadata.
///
/// Uses a file-backed [InputFileStream] so only the header bytes (and any
/// entry whose content is explicitly requested) are read, not the whole
/// archive. Directory entries are dropped and only the base name is kept,
/// matching how MAME stores a flat set inside one zip.
List<ZipEntryInfo> readZipEntries(String zipPath) {
  final stream = InputFileStream(zipPath);
  try {
    final directory = ZipDirectory.read(stream);
    final entries = <ZipEntryInfo>[];
    for (final header in directory.fileHeaders) {
      final name = header.filename;
      if (name.endsWith('/')) continue; // directory marker
      final crc = header.crc32 ?? 0;
      entries.add(ZipEntryInfo(
        name: p.basename(name),
        size: header.uncompressedSize ?? 0,
        crc: (crc & 0xFFFFFFFF).toRadixString(16).toLowerCase().padLeft(8, '0'),
      ));
    }
    return entries;
  } finally {
    stream.closeSync();
  }
}

// ── Auditor ──────────────────────────────────────────────────────────────────

/// Options controlling how strict the audit is.
class MameAuditOptions {
  /// Treat a CRC mismatch as a failure (default) or only a size mismatch.
  final bool verifyCrc;

  /// Report machines that have no zip as `missing` (default) or skip them.
  final bool reportMissingSets;

  /// Only audit machines that have a ROM zip present.
  final bool onlyPresentSets;

  /// Include BIOS/device-only sets in the report.
  final bool includeBiosSets;

  const MameAuditOptions({
    this.verifyCrc = true,
    this.reportMissingSets = true,
    this.onlyPresentSets = false,
    this.includeBiosSets = false,
  });
}

/// Audits a folder of arcade ZIP archives against a parsed [MameDat].
class MameAuditor {
  final MameDat dat;
  final MameAuditOptions options;

  /// Per-set ZIP entry index, populated lazily as archives are scanned.
  final Map<String, List<ZipEntryInfo>> _zipCache = {};

  /// Slugs that exist as `.zip` in the folder (case-insensitive lookup).
  final Map<String, String> _zipBySlugLower = {};

  /// CHD paths found in the folder, keyed by `<set>/<disk>.chd` lower-cased.
  final Map<String, String> _chdByPathLower = {};

  /// Any CHD file present, keyed by base name lower-cased.
  final Map<String, String> _chdByBaseLower = {};

  MameAuditor(this.dat, {this.options = const MameAuditOptions()});

  /// Scans [folder] once and builds the slug / CHD lookup tables.
  void _indexFolder(String folder) {
    _zipBySlugLower.clear();
    _chdByPathLower.clear();
    _chdByBaseLower.clear();

    final dir = Directory(folder);
    if (!dir.existsSync()) return;

    for (final entity in dir.listSync()) {
      if (entity is File) {
        final base = p.basename(entity.path);
        final ext = p.extension(base).toLowerCase();
        if (ext == '.zip') {
          final slug = base.substring(0, base.length - 4);
          _zipBySlugLower[slug.toLowerCase()] = entity.path;
        } else if (ext == '.chd') {
          _chdByBaseLower[base.toLowerCase()] = entity.path;
        }
      } else if (entity is Directory) {
        // Arcade CHDs live in a subfolder named after the machine, e.g.
        // `kinst/kinst.chd` or `kinst/diskname.chd`.
        final subName = p.basename(entity.path);
        for (final sub in entity.listSync()) {
          if (sub is! File) continue;
          final chdBase = p.basename(sub.path);
          if (p.extension(chdBase).toLowerCase() != '.chd') continue;
          _chdByPathLower['$subName/$chdBase'.toLowerCase()] = sub.path;
          _chdByBaseLower.putIfAbsent(chdBase.toLowerCase(), () => sub.path);
        }
      }
    }
  }

  String? _zipPathFor(String slug) => _zipBySlugLower[slug.toLowerCase()];

  List<ZipEntryInfo>? _entriesFor(String slug) {
    final path = _zipPathFor(slug);
    if (path == null) return null;
    final cached = _zipCache[path];
    if (cached != null) return cached;
    try {
      final entries = readZipEntries(path);
      _zipCache[path] = entries;
      return entries;
    } catch (_) {
      _zipCache[path] = const [];
      return const [];
    }
  }

  /// Looks up a CHD for [machineName] / [diskName], checking the machine
  /// subfolder first, then a flat file beside the zip.
  String? _findChd(String machineName, String diskName) {
    final inSub = _chdByPathLower['$machineName/$diskName.chd'.toLowerCase()];
    if (inSub != null) return inSub;
    return _chdByBaseLower['$diskName.chd'.toLowerCase()];
  }

  /// Runs the audit over [folder] and returns the aggregate report.
  MameAuditReport audit(String folder,
      {void Function(int done, int total)? onProgress}) {
    _indexFolder(folder);

    // Only audit machines that are actually games: BIOS and device sets are
    // helper bundles, not user-facing titles, unless explicitly requested.
    final targets = <MameMachine>[];
    var skipped = 0;
    for (final machine in dat.machines.values) {
      if ((machine.isBios || machine.isDevice) && !options.includeBiosSets) {
        skipped++;
        continue;
      }
      if (options.onlyPresentSets && _zipPathFor(machine.name) == null) {
        continue;
      }
      targets.add(machine);
    }

    final results = <MameAuditResult>[];
    var done = 0;
    for (final machine in targets) {
      results.add(auditMachine(machine));
      done++;
      if (onProgress != null && done % 200 == 0) {
        onProgress(done, targets.length);
      }
    }
    if (onProgress != null && done > 0) {
      onProgress(done, targets.length);
    }

    return MameAuditReport(
      datName: dat.name,
      folder: folder,
      results: results,
      skippedDevices: skipped,
    );
  }

  /// Audits a single [machine] against the indexed folder.
  MameAuditResult auditMachine(MameMachine machine) {
    final zipPath = _zipPathFor(machine.name);
    final ownDisks = machine.disks
        .where((d) => d.merge == null || d.merge!.isEmpty)
        .toList();

    // When missing sets are not reported and the machine has neither a zip nor
    // a CHD to look for, there is nothing to say about it.
    if (zipPath == null && ownDisks.isEmpty && !options.reportMissingSets) {
      return MameAuditResult(
        name: machine.name,
        description: machine.description,
        status: MameAuditStatus.complete,
        detail: 'No zip present (not reported)',
        isClone: machine.isClone,
        isBios: machine.isBios,
      );
    }

    List<ZipEntryInfo>? entries;
    if (zipPath != null) {
      entries = _entriesFor(machine.name);
      if (entries == null || entries.isEmpty) {
        // The archive exists but yielded no readable entries.
        return MameAuditResult(
          name: machine.name,
          description: machine.description,
          status: MameAuditStatus.error,
          detail: 'Zip archive could not be read: ${p.basename(zipPath)}',
          isClone: machine.isClone,
          isBios: machine.isBios,
        );
      }
    }

    // Effective ROM set: the machine's own ROMs, excluding merged entries that
    // are supplied by a parent/BIOS (those are verified against that set).
    final missingRoms = <MameMissingEntry>[];
    final missingBios = <String>[];
    final missingParents = <String>[];
    var romsChecked = 0;
    var romsPresent = 0;

    // Split-set semantics: a clone in a split set only needs its *own* ROMs
    // (those without a `merge` attribute pointing at the parent); the merged
    // ones come from the parent zip, which we verify separately.
    final ownRoms =
        machine.roms.where((r) => r.merge == null || r.merge!.isEmpty).toList();

    for (final rom in ownRoms) {
      romsChecked++;
      if (entries == null) {
        missingRoms.add(MameMissingEntry(
          kind: 'rom',
          name: rom.name,
          expectedSize: rom.size,
          expectedCrc: rom.crc,
        ));
        continue;
      }
      final entry = _findEntry(entries, rom.name);
      if (entry == null) {
        missingRoms.add(MameMissingEntry(
          kind: 'rom',
          name: rom.name,
          expectedSize: rom.size,
          expectedCrc: rom.crc,
        ));
        continue;
      }
      if (!_entryMatches(entry, rom)) {
        missingRoms.add(MameMissingEntry(
          kind: 'rom',
          name: rom.name,
          expectedSize: rom.size,
          expectedCrc: rom.crc,
          reason: 'crc_mismatch',
          actualCrc: entry.crc,
        ));
        continue;
      }
      romsPresent++;
    }

    // BIOS dependency: `romof` points at a BIOS/parent set that must be
    // present as its own zip (e.g. `neogeo`). A `romof` that is itself the
    // clone's parent is handled by the parent check below instead.
    final romOf = machine.romOf;
    if (romOf != null && romOf.isNotEmpty && romOf != machine.cloneOf) {
      final biosZip = _zipPathFor(romOf);
      if (biosZip == null) {
        missingBios.add(romOf);
      } else if (!_biosSetComplete(romOf)) {
        // Present but missing the chips this machine borrows.
        missingBios.add(romOf);
      }
    }

    // Parent dependency for clones in a split set: the parent zip must exist
    // unless every borrowed ROM is merged into this zip.
    if (machine.isClone) {
      final parent = machine.cloneOf!;
      final parentZip = _zipPathFor(parent);
      if (parentZip == null) {
        // Only a problem if this clone actually borrows ROMs from the parent.
        final borrows =
            machine.roms.where((r) => r.merge != null && r.merge!.isNotEmpty);
        if (borrows.isNotEmpty || romOf == parent) {
          missingParents.add(parent);
        }
      } else if (!_biosSetComplete(parent)) {
        missingParents.add(parent);
      }
    }

    // CHD disks: each `<disk name="foo">` must resolve to `foo.chd`, either in
    // a `<machine>/` subfolder or beside the zip.
    final missingDisks = <MameMissingEntry>[];
    var disksChecked = 0;
    var disksPresent = 0;
    for (final disk in ownDisks) {
      disksChecked++;
      if (_findChd(machine.name, disk.name) != null) {
        disksPresent++;
      } else {
        missingDisks.add(MameMissingEntry(
          kind: 'disk',
          name: '${disk.name}.chd',
          reason: 'missing',
        ));
      }
    }

    // ── Verdict ──────────────────────────────────────────────────────────────
    MameAuditStatus status;
    String detail;

    if (zipPath == null && ownRoms.isNotEmpty) {
      status = MameAuditStatus.missing;
      detail = 'No ${machine.name}.zip in folder';
    } else if (missingBios.isNotEmpty) {
      status = MameAuditStatus.missingBios;
      detail =
          'Missing required BIOS: ${missingBios.map((b) => '$b.zip').join(', ')}';
    } else if (missingParents.isNotEmpty) {
      status = MameAuditStatus.missingParent;
      detail =
          'Clone missing parent set: ${missingParents.map((b) => '$b.zip').join(', ')}';
    } else if (missingRoms.isNotEmpty) {
      status = MameAuditStatus.incomplete;
      detail =
          '${missingRoms.length} of $romsChecked ROM chip(s) missing or mismatched';
    } else if (missingDisks.isNotEmpty) {
      status = MameAuditStatus.missingChd;
      detail = 'Missing CHD: ${missingDisks.map((d) => d.name).join(', ')}';
    } else {
      status = MameAuditStatus.complete;
      detail = romsChecked == 0 && disksChecked == 0
          ? 'No ROMs or disks declared'
          : 'All $romsChecked ROM(s)'
              '${disksChecked > 0 ? ' and $disksChecked disk(s)' : ''} present';
    }

    return MameAuditResult(
      name: machine.name,
      description: machine.description,
      status: status,
      detail: detail,
      missingRoms: missingRoms,
      missingDisks: missingDisks,
      missingBios: missingBios,
      missingParents: missingParents,
      romsChecked: romsChecked,
      romsPresent: romsPresent,
      disksChecked: disksChecked,
      disksPresent: disksPresent,
      isClone: machine.isClone,
      isBios: machine.isBios,
    );
  }

  /// Returns `true` when the BIOS/parent set [slug] has a zip whose entries
  /// cover all the non-merged ROMs the DAT declares for it.
  bool _biosSetComplete(String slug) {
    final machine = dat.machines[slug];
    if (machine == null) {
      // Unknown set in the DAT: presence of the zip is all we can check.
      return _zipPathFor(slug) != null;
    }
    final entries = _entriesFor(slug);
    if (entries == null) return false;

    for (final rom in machine.roms) {
      if (rom.merge != null && rom.merge!.isNotEmpty) continue;
      final entry = _findEntry(entries, rom.name);
      if (entry == null) return false;
      if (!_entryMatches(entry, rom)) return false;
    }
    return true;
  }

  ZipEntryInfo? _findEntry(List<ZipEntryInfo> entries, String romName) {
    final target = p.basename(romName).toLowerCase();
    for (final e in entries) {
      if (e.name.toLowerCase() == target) return e;
    }
    return null;
  }

  bool _entryMatches(ZipEntryInfo entry, MameRom rom) {
    if (rom.size > 0 && entry.size != rom.size) return false;
    if (options.verifyCrc && rom.crc.isNotEmpty && entry.crc != rom.crc) {
      return false;
    }
    return true;
  }

  /// Disposes any resources. Archives are streamed and closed per read, so
  /// this exists to clear the in-memory caches.
  void dispose() {
    _zipCache.clear();
  }
}

// ── Convenience entry point ──────────────────────────────────────────────────

/// Parses [datPath], audits [folder], and returns the report in one call.
Future<MameAuditReport> auditMameCollection({
  required String datPath,
  required String folder,
  MameAuditOptions options = const MameAuditOptions(),
  void Function(String stage, int done, int total)? onProgress,
}) async {
  final dat = await parseMameDat(
    datPath,
    onProgress: (n) => onProgress?.call('parse', n, 0),
  );
  final auditor = MameAuditor(dat, options: options);
  try {
    return auditor.audit(
      folder,
      onProgress: (done, total) => onProgress?.call('audit', done, total),
    );
  } finally {
    auditor.dispose();
  }
}
