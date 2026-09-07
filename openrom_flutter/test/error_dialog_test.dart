// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3 + Commons Clause

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openrom_flutter/core/error_dialog.dart';
import 'package:openrom_flutter/core/errors.dart';
import 'package:openrom_flutter/l10n/app_localizations.dart';
import 'package:openrom_flutter/models/conversion_job.dart';
import 'package:openrom_flutter/models/rom_file.dart';
import 'package:openrom_flutter/models/theme_config.dart';
import 'package:openrom_flutter/widgets/rom_card.dart';

Widget _wrapWithLocalizations(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('Error Dialog & RomCard Tests', () {
    testWidgets('showOpenROMError displays dialog with title, message and action', (tester) async {
      bool actionCalled = false;

      await tester.pumpWidget(
        _wrapWithLocalizations(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showOpenROMError(
                    context,
                    OpenROMError.coreNotFound,
                    details: 'Sample raw error stacktrace',
                    onAction: () => actionCalled = true,
                  );
                },
                child: const Text('Show Error'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show Error'));
      await tester.pumpAndSettle();

      expect(find.text('Backend Not Found'), findsOneWidget);
      expect(find.text('openrom-core is missing from the app folder.'), findsOneWidget);
      expect(find.text('Please re-download the full ZIP from GitHub.'), findsOneWidget);
      expect(find.text('Details'), findsOneWidget);

      // Expand details
      await tester.tap(find.text('Details'));
      await tester.pumpAndSettle();
      expect(find.text('Sample raw error stacktrace'), findsOneWidget);

      // Tap action button
      await tester.tap(find.text('Open GitHub'));
      await tester.pumpAndSettle();

      expect(actionCalled, isTrue);
    });

    testWidgets('RomCard displays failed state with error icon and responds to tap', (tester) async {
      final rom = RomFile(
        filename: 'TestGame.bin',
        filepath: '/path/to/TestGame.bin',
        sizeBytes: 1024,
        sizeStr: '1 KB',
        format: 'BIN',
        platform: 'PS1',
        badgeColor: '#000000',
        validTargets: ['CHD'],
      );

      final job = ConversionJob(
        id: '1',
        romFile: rom,
        targetFormat: 'CHD',
        status: JobStatus.failed,
        error: OpenROMError.toolFailed,
        errorMessage: 'chdman failed with exit code 1',
      );

      final theme = ThemeConfig.defaultTheme();

      await tester.pumpWidget(
        _wrapWithLocalizations(
          RomCard(
            job: job,
            theme: theme,
            onDelete: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show failed status icon/indicator
      expect(find.byIcon(Icons.error_outline), findsWidgets);

      // Tap card to open error dialog
      await tester.tap(find.byType(RomCard));
      await tester.pumpAndSettle();

      expect(find.text('Tool Crashed'), findsOneWidget);

      // Expand details
      await tester.tap(find.text('Details'));
      await tester.pumpAndSettle();
      expect(find.text('chdman failed with exit code 1'), findsOneWidget);
    });
  });
}
