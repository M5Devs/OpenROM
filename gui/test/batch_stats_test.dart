// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gui/l10n/app_localizations.dart';
import 'package:gui/models/batch_stats.dart';
import 'package:gui/models/theme_config.dart';
import 'package:gui/widgets/batch_complete_dialog.dart';

void main() {
  group('BatchStats (GUI model)', () {
    test('computes savings and percentage', () {
      const stats = BatchStats(
        jobsCompleted: 2,
        totalOriginalBytes: 1000,
        totalOutputBytes: 400,
      );
      expect(stats.bytesSaved, 600);
      expect(stats.savedPercentage, closeTo(60.0, 0.001));
      expect(stats.savedPercentageReadable, '60.0%');
      expect(stats.hasSavings, isTrue);
    });

    test('spec example: 70 GB in, 25 GB out ~= 64.3%', () {
      const stats = BatchStats(
        jobsCompleted: 12,
        totalOriginalBytes: 75161927680,
        totalOutputBytes: 26843545600,
      );
      expect(stats.bytesSavedReadable, '45.0 GB');
      expect(stats.savedPercentageReadable, '64.3%');
    });

    test('reports no savings when output is equal or larger', () {
      const equal = BatchStats(
        jobsCompleted: 1,
        totalOriginalBytes: 100,
        totalOutputBytes: 100,
      );
      expect(equal.hasSavings, isFalse);
      expect(equal.bytesSavedReadable, '0.0 B');

      const expanded = BatchStats(
        jobsCompleted: 1,
        totalOriginalBytes: 100,
        totalOutputBytes: 250,
      );
      expect(expanded.hasSavings, isFalse);
      expect(expanded.bytesSavedReadable, '-150.0 B');
      expect(expanded.savedPercentageReadable, '-150.0%');
    });

    test('fromJson parses core completion payload', () {
      final stats = BatchStats.fromJson({
        'type': 'done',
        'success': true,
        'jobs_completed': 12,
        'original_bytes': 75161927680,
        'output_bytes': 26843545600,
        'bytes_saved': 48318382080,
        'bytes_saved_readable': '45.0 GB',
        'saved_percentage': '64.3%',
      });
      expect(stats.jobsCompleted, 12);
      expect(stats.bytesSavedReadable, '45.0 GB');
      expect(stats.savedPercentageReadable, '64.3%');
    });

    test('fromJson tolerates a bare done event', () {
      final stats = BatchStats.fromJson({'type': 'done', 'success': true});
      expect(stats.jobsCompleted, 0);
      expect(stats.totalOriginalBytes, 0);
      expect(stats.hasSavings, isFalse);
    });

    test('operator + accumulates across jobs', () {
      const a = BatchStats(
        jobsCompleted: 1,
        totalOriginalBytes: 1000,
        totalOutputBytes: 400,
      );
      const b = BatchStats(
        jobsCompleted: 2,
        totalOriginalBytes: 500,
        totalOutputBytes: 100,
      );
      final sum = a + b;
      expect(sum.jobsCompleted, 3);
      expect(sum.totalOriginalBytes, 1500);
      expect(sum.totalOutputBytes, 500);
      expect(sum.bytesSaved, 1000);
    });
  });

  group('BatchCompleteDialog', () {
    final theme = ThemeConfig.defaultTheme();

    Widget host(BatchStats stats, {String outputDir = ''}) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (ctx) => Center(
              child: ElevatedButton(
                onPressed: () => showBatchCompleteDialog(
                  ctx,
                  stats: stats,
                  theme: theme,
                  outputDir: outputDir,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('shows the saved figure when space was reclaimed',
        (tester) async {
      await tester.pumpWidget(host(const BatchStats(
        jobsCompleted: 3,
        totalOriginalBytes: 1000,
        totalOutputBytes: 400,
      )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Batch Complete! 🎉'), findsOneWidget);
      expect(find.textContaining('You just saved'), findsOneWidget);
      expect(find.textContaining('60.0%'), findsOneWidget);
      expect(find.textContaining('across 3 games'), findsOneWidget);
      expect(find.text('Awesome!'), findsOneWidget);
    });

    testWidgets('uses the singular noun for a single game', (tester) async {
      await tester.pumpWidget(host(const BatchStats(
        jobsCompleted: 1,
        totalOriginalBytes: 1000,
        totalOutputBytes: 400,
      )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.textContaining('across 1 game!'), findsOneWidget);
    });

    testWidgets('falls back to the success message when nothing was saved',
        (tester) async {
      await tester.pumpWidget(host(const BatchStats(
        jobsCompleted: 4,
        totalOriginalBytes: 1000,
        totalOutputBytes: 1000,
      )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('All 4 files processed successfully!'),
        findsOneWidget,
      );
      expect(find.textContaining('You just saved'), findsNothing);
    });

    testWidgets('shows Open Output Folder only when an output dir is known',
        (tester) async {
      await tester.pumpWidget(host(
        const BatchStats(
          jobsCompleted: 1,
          totalOriginalBytes: 1000,
          totalOutputBytes: 400,
        ),
        outputDir: '/tmp/does-not-matter',
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Open Output Folder'), findsOneWidget);
    });

    testWidgets('dismisses on Awesome!', (tester) async {
      await tester.pumpWidget(host(const BatchStats(
        jobsCompleted: 1,
        totalOriginalBytes: 1000,
        totalOutputBytes: 400,
      )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Awesome!'));
      await tester.pumpAndSettle();
      expect(find.text('Batch Complete! 🎉'), findsNothing);
    });
  });
}
