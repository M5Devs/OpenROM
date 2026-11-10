// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

/// Aggregate size statistics for a conversion batch, mirroring the payload the
/// core emits on its completion (`done`) event.
class BatchStats {
  final int jobsCompleted;
  final int totalOriginalBytes;
  final int totalOutputBytes;

  const BatchStats({
    required this.jobsCompleted,
    required this.totalOriginalBytes,
    required this.totalOutputBytes,
  });

  static const BatchStats empty =
      BatchStats(jobsCompleted: 0, totalOriginalBytes: 0, totalOutputBytes: 0);

  int get bytesSaved => totalOriginalBytes - totalOutputBytes;

  double get savedPercentage =>
      totalOriginalBytes <= 0 ? 0.0 : (bytesSaved / totalOriginalBytes) * 100.0;

  /// True only when the batch genuinely shrank the data.
  bool get hasSavings => bytesSaved > 0;

  String get bytesSavedReadable => humanBytes(bytesSaved);

  String get savedPercentageReadable =>
      '${savedPercentage.toStringAsFixed(1)}%';

  /// Parses the fields the core adds to a completion event. Missing keys fall
  /// back to zero so a plain `{"type":"done","success":true}` still parses.
  factory BatchStats.fromJson(Map<String, dynamic> json) {
    return BatchStats(
      jobsCompleted: (json['jobs_completed'] as num?)?.toInt() ?? 0,
      totalOriginalBytes: (json['original_bytes'] as num?)?.toInt() ?? 0,
      totalOutputBytes: (json['output_bytes'] as num?)?.toInt() ?? 0,
    );
  }

  BatchStats operator +(BatchStats other) => BatchStats(
        jobsCompleted: jobsCompleted + other.jobsCompleted,
        totalOriginalBytes: totalOriginalBytes + other.totalOriginalBytes,
        totalOutputBytes: totalOutputBytes + other.totalOutputBytes,
      );
}

/// Formats a byte count using binary (1024-based) units, e.g. `45.0 GB`.
/// Negative values keep their sign so "space expanded" figures read correctly.
String humanBytes(int size) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  double value = size.abs().toDouble();
  int i = 0;
  while (value >= 1024 && i < units.length - 1) {
    value /= 1024;
    i++;
  }
  final text = '${value.toStringAsFixed(1)} ${units[i]}';
  return size < 0 ? '-$text' : text;
}
