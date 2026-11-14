// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gui/l10n/app_localizations.dart';
import 'package:gui/models/theme_config.dart';
import 'package:gui/screens/tools_screen.dart';

void main() {
  group('ToolsScreen Widget Tests', () {
    final theme = ThemeConfig.defaultTheme();

    Widget createToolsScreen() {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ToolsScreen(theme: theme),
      );
    }

    testWidgets('Renders Tools tabs and compressor UI', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createToolsScreen());
      await tester.pumpAndSettle();

      expect(find.text('ROM Compressor'), findsNWidgets(2));
      expect(find.text('M3U Generator'), findsOneWidget);
      expect(find.text('CUE Generator'), findsOneWidget);
      expect(find.text('BIN Merger'), findsOneWidget);
      expect(find.text('Header Remover'), findsOneWidget);
      expect(find.text('Add Files'), findsOneWidget);
      expect(find.text('Add Folder'), findsOneWidget);
      expect(find.text('Output Format'), findsOneWidget);
      expect(find.text('ZIP'), findsOneWidget);
      expect(find.text('7Z'), findsOneWidget);
      expect(find.text('Extract'), findsOneWidget);
    });

    testWidgets('Switches sub-tabs between tools', (WidgetTester tester) async {
      await tester.pumpWidget(createToolsScreen());
      await tester.pumpAndSettle();

      final m3uTabFinder = find.widgetWithText(Tab, 'M3U Generator');
      expect(m3uTabFinder, findsOneWidget);
      await tester.tap(m3uTabFinder);
      await tester.pumpAndSettle();
      expect(find.text('Generate M3U'), findsOneWidget);
      expect(find.text('Output folder'), findsOneWidget);

      final cueTabFinder = find.widgetWithText(Tab, 'CUE Generator');
      expect(cueTabFinder, findsOneWidget);
      await tester.tap(cueTabFinder);
      await tester.pumpAndSettle();
      expect(find.text('Generate CUE'), findsOneWidget);
      expect(find.text('BIN File'), findsOneWidget);

      final binMergerTabFinder = find.widgetWithText(Tab, 'BIN Merger');
      expect(binMergerTabFinder, findsOneWidget);
      await tester.tap(binMergerTabFinder);
      await tester.pumpAndSettle();
      expect(find.text('Merge BINs'), findsOneWidget);
      expect(find.text('CUE File (multi-track)'), findsOneWidget);

      final headerRemoverTabFinder = find.widgetWithText(Tab, 'Header Remover');
      expect(headerRemoverTabFinder, findsOneWidget);
      await tester.tap(headerRemoverTabFinder);
      await tester.pumpAndSettle();
      expect(find.text('Remove Header'), findsOneWidget);
      expect(find.text('Keep backup (.bak)'), findsOneWidget);

      final hasherTabFinder = find.widgetWithText(Tab, 'ROM Hasher');
      expect(hasherTabFinder, findsOneWidget);
      await tester.tap(hasherTabFinder);
      await tester.pumpAndSettle();
      expect(find.text('Compute Hashes'), findsOneWidget);
      expect(
        find.text('Compute CRC32, MD5, SHA-1 and SHA-256 in a single '
            'streaming pass.'),
        findsOneWidget,
      );

      final watchTabFinder = find.widgetWithText(Tab, 'Watch Folder');
      expect(watchTabFinder, findsOneWidget);
      await tester.tap(watchTabFinder);
      await tester.pumpAndSettle();
      expect(find.text('Watch Folder'), findsNWidgets(2));
      expect(find.text('Input Folder'), findsOneWidget);
      expect(find.text('Output Folder'), findsOneWidget);
      expect(find.text('Target Format'), findsOneWidget);
      expect(find.text('Delete source after conversion'), findsOneWidget);
      expect(find.text('Start Watching'), findsOneWidget);
      expect(find.text('No activity yet.'), findsOneWidget);

      final arcadeTabFinder = find.widgetWithText(Tab, 'Arcade / MAME');
      expect(arcadeTabFinder, findsOneWidget);
      await tester.tap(arcadeTabFinder);
      await tester.pumpAndSettle();
      expect(find.text('Select MAME XML / DAT file'), findsOneWidget);
      expect(find.text('Select Arcade ROMs Folder'), findsOneWidget);
      expect(find.text('Audit Arcade Collection'), findsOneWidget);
      expect(find.text('No DAT selected'), findsOneWidget);
      expect(find.text('No folder selected'), findsOneWidget);
    });
  });
}
