import 'package:openrom_core/openrom_core.dart';
import 'package:test/test.dart';

void main() {
  group('humanBytes', () {
    test('formats binary units to one decimal place', () {
      expect(humanBytes(0), '0.0 B');
      expect(humanBytes(512), '512.0 B');
      expect(humanBytes(1024), '1.0 KB');
      expect(humanBytes(1536), '1.5 KB');
      expect(humanBytes(1024 * 1024), '1.0 MB');
      expect(humanBytes(48318382080), '45.0 GB');
      expect(humanBytes(75161927680), '70.0 GB');
      expect(humanBytes(1024 * 1024 * 1024 * 1024), '1.0 TB');
    });

    test('keeps the sign for expanded (negative) savings', () {
      expect(humanBytes(-2048), '-2.0 KB');
    });
  });

  group('BatchStats', () {
    test('computes bytes saved and percentage from successful jobs', () {
      final stats = BatchStats(
        jobsCompleted: 2,
        totalOriginalBytes: 1000,
        totalOutputBytes: 400,
      );
      expect(stats.bytesSaved, 600);
      expect(stats.savedPercentage, closeTo(60.0, 0.001));
      expect(stats.bytesSavedReadable, '600.0 B');
      expect(stats.savedPercentageReadable, '60.0%');
    });

    test('spec example: 70 GB in, 25 GB out ~= 64.3%', () {
      const original = 75161927680; // 70.0 GB
      const output = 26843545600; // 25.0 GB
      final stats = BatchStats(
        jobsCompleted: 12,
        totalOriginalBytes: original,
        totalOutputBytes: output,
      );
      expect(stats.bytesSaved, 48318382080);
      expect(stats.bytesSavedReadable, '45.0 GB');
      expect(stats.savedPercentageReadable, '64.3%');
    });

    test('handles expansion (negative savings) with a signed percentage', () {
      final stats = BatchStats(
        jobsCompleted: 1,
        totalOriginalBytes: 100,
        totalOutputBytes: 150,
      );
      expect(stats.bytesSaved, -50);
      expect(stats.savedPercentageReadable, '-50.0%');
    });

    test('guards against division by zero when there is no input', () {
      const stats = BatchStats(
        jobsCompleted: 0,
        totalOriginalBytes: 0,
        totalOutputBytes: 0,
      );
      expect(stats.bytesSaved, 0);
      expect(stats.savedPercentage, 0.0);
      expect(stats.savedPercentageReadable, '0.0%');
    });

    test('fromJobs sums only jobs whose status is Done', () {
      final done = ConversionJob(
        filepath: '/a.iso',
        outputDir: '/out',
        targetFormat: 'CHD',
      )
        ..status = 'Done'
        ..originalSizeBytes = 1000
        ..outputSizeBytes = 250;
      final failed = ConversionJob(
        filepath: '/b.iso',
        outputDir: '/out',
        targetFormat: 'CHD',
      )
        ..status = 'Failed'
        ..originalSizeBytes = 9999
        ..outputSizeBytes = 0;
      final queued = ConversionJob(
        filepath: '/c.iso',
        outputDir: '/out',
        targetFormat: 'CHD',
      );

      final stats = BatchStats.fromJobs([done, failed, queued]);
      expect(stats.jobsCompleted, 1);
      expect(stats.totalOriginalBytes, 1000);
      expect(stats.totalOutputBytes, 250);
      expect(stats.bytesSaved, 750);
    });

    test('toJson emits the documented payload keys', () {
      const stats = BatchStats(
        jobsCompleted: 1,
        totalOriginalBytes: 1024,
        totalOutputBytes: 512,
      );
      expect(stats.toJson(), {
        'jobs_completed': 1,
        'original_bytes': 1024,
        'output_bytes': 512,
        'bytes_saved': 512,
        'bytes_saved_readable': '512.0 B',
        'saved_percentage': '50.0%',
      });
    });
  });
}
