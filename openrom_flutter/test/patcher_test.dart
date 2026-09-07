// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3 + Commons Clause

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openrom_flutter/l10n/app_localizations.dart';
import 'package:openrom_flutter/models/theme_config.dart';
import 'package:openrom_flutter/patcher/patcher.dart';
import 'package:openrom_flutter/patcher/patcher_factory.dart';
import 'package:openrom_flutter/screens/patcher_screen.dart';
import 'package:openrom_flutter/services/patcher_service.dart';

class MockPatcherService extends PatcherService {
  final Future<PatchReport> Function({
    required String romPath,
    required String patchPath,
    required String outputPath,
    bool ignoreChecksum,
  })? onApplyPatch;

  MockPatcherService({this.onApplyPatch});

  @override
  Future<PatchReport> applyPatch({
    required String romPath,
    required String patchPath,
    required String outputPath,
    bool ignoreChecksum = false,
  }) async {
    if (onApplyPatch != null) {
      return await onApplyPatch!(
        romPath: romPath,
        patchPath: patchPath,
        outputPath: outputPath,
        ignoreChecksum: ignoreChecksum,
      );
    }
    return const PatchReport(format: 'bps', checks: [
      PatchCheck('Source CRC32', CheckOutcome.passed),
      PatchCheck('Target CRC32', CheckOutcome.passed),
    ]);
  }
}

void main() {
  group('PatcherFactory Tests', () {
    test('Identifies supported patch extensions', () {
      expect(PatcherFactory.isSupportedPatch('game.ips'), isTrue);
      expect(PatcherFactory.isSupportedPatch('game.IPS32'), isTrue);
      expect(PatcherFactory.isSupportedPatch('game.bps'), isTrue);
      expect(PatcherFactory.isSupportedPatch('game.xdelta'), isTrue);
      expect(PatcherFactory.isSupportedPatch('game.iso'), isFalse);
    });

    test('Returns human-readable format names', () {
      expect(PatcherFactory.formatName('patch.bps'), 'BPS');
      expect(PatcherFactory.formatName('patch.ips'), 'IPS');
      expect(PatcherFactory.formatName('patch.vcdiff'), 'xdelta');
      expect(PatcherFactory.formatName('patch.unknown'), isNull);
    });
  });

  group('PatcherScreen Widget Tests', () {
    final theme = ThemeConfig.defaultTheme();

    Widget createPatcherScreen({PatcherService? service}) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PatcherScreen(
            theme: theme,
            patcherService: service,
          ),
        ),
      );
    }

    testWidgets('Renders all main UI components', (WidgetTester tester) async {
      await tester.pumpWidget(createPatcherScreen());
      await tester.pumpAndSettle();

      expect(find.text('ROM Patcher'), findsOneWidget);
      expect(find.text('ROM File'), findsOneWidget);
      expect(find.text('Patch File'), findsOneWidget);
      expect(find.text('Output File'), findsOneWidget);
      expect(find.text('Same folder as ROM'), findsOneWidget);
      expect(find.text('Ignore checksum errors'), findsOneWidget);
      expect(find.text('Apply Patch'), findsOneWidget);
    });

    testWidgets('Apply Patch button is disabled when fields are empty', (WidgetTester tester) async {
      await tester.pumpWidget(createPatcherScreen());
      await tester.pumpAndSettle();

      final buttonFinder = find.widgetWithText(ElevatedButton, 'Apply Patch');
      expect(buttonFinder, findsOneWidget);
      final elevatedButton = tester.widget<ElevatedButton>(buttonFinder);
      expect(elevatedButton.onPressed, isNull);
    });
  });
}
