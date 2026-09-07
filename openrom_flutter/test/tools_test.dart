// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3 + Commons Clause

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openrom_flutter/l10n/app_localizations.dart';
import 'package:openrom_flutter/models/theme_config.dart';
import 'package:openrom_flutter/screens/tools_screen.dart';

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

    testWidgets('Renders Tools tabs and compressor UI', (WidgetTester tester) async {
      await tester.pumpWidget(createToolsScreen());
      await tester.pumpAndSettle();

      expect(find.text('ROM Compressor'), findsNWidgets(2));
      expect(find.text('M3U Generator'), findsOneWidget);
      expect(find.text('Add Files'), findsOneWidget);
      expect(find.text('Add Folder'), findsOneWidget);
      expect(find.text('Output Format'), findsOneWidget);
      expect(find.text('ZIP'), findsOneWidget);
      expect(find.text('7Z'), findsOneWidget);
      expect(find.text('Extract'), findsOneWidget);
    });

    testWidgets('Switches sub-tabs between ROM Compressor and M3U Generator', (WidgetTester tester) async {
      await tester.pumpWidget(createToolsScreen());
      await tester.pumpAndSettle();

      final m3uTabFinder = find.widgetWithText(Tab, 'M3U Generator');
      expect(m3uTabFinder, findsOneWidget);

      await tester.tap(m3uTabFinder);
      await tester.pumpAndSettle();

      expect(find.text('Generate M3U'), findsOneWidget);
      expect(find.text('Output folder'), findsOneWidget);
    });
  });
}
