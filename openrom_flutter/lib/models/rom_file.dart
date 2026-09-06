// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3 + Commons Clause

class RomFile {
  final String filepath;
  final String filename;
  final String format;
  final String platform;
  final int sizeBytes;
  final String sizeStr;
  final List<String> validTargets;
  final String badgeColor;
  final bool needsEcmDecode;
  final String? pairedCue;
  final String? pairedBin;
  final String? chdType;

  RomFile({
    required this.filepath,
    required this.filename,
    required this.format,
    required this.platform,
    required this.sizeBytes,
    required this.sizeStr,
    required this.validTargets,
    required this.badgeColor,
    this.needsEcmDecode = false,
    this.pairedCue,
    this.pairedBin,
    this.chdType,
  });

  factory RomFile.fromJson(Map<String, dynamic> json) {
    return RomFile(
      filepath: json['filepath'] ?? '',
      filename: json['filename'] ?? (json['filepath'] != null ? json['filepath'].split('/')['last'] : ''),
      format: json['format'] ?? 'UNKNOWN',
      platform: json['platform'] ?? 'ROM File',
      sizeBytes: json['size_bytes'] ?? 0,
      sizeStr: json['size_str'] ?? '0 B',
      validTargets: (json['valid_targets'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      badgeColor: json['badge_color'] ?? '#7a8a9a',
      needsEcmDecode: json['needs_ecm_decode'] ?? false,
      pairedCue: json['paired_cue'],
      pairedBin: json['paired_bin'],
      chdType: json['chd_type'],
    );
  }
}
