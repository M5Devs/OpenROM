// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gui/models/theme_config.dart';
import 'package:gui/services/tools_service.dart';
import 'package:gui/widgets/arcade_audit_view.dart';

ArcadeGameAudit _game({
  required String name,
  required String description,
  required String status,
  List<String> missingBios = const [],
  List<String> missingParents = const [],
  List<ArcadeMissingEntry> missingRoms = const [],
  List<ArcadeMissingEntry> missingDisks = const [],
  int romsChecked = 1,
  int romsPresent = 1,
}) {
  return ArcadeGameAudit(
    name: name,
    description: description,
    status: status,
    statusLabel: status,
    detail: 'detail for $name',
    romsChecked: romsChecked,
    romsPresent: romsPresent,
    missingBios: missingBios,
    missingParents: missingParents,
    missingRoms: missingRoms,
    missingDisks: missingDisks,
  );
}

void main() {
  final theme = ThemeConfig.defaultTheme();

  ArcadeAuditReport sampleReport() => ArcadeAuditReport(
        datName: 'mame',
        folder: '/roms',
        totalGames: 3,
        complete: 1,
        missingBios: 1,
        incomplete: 1,
        healthPercent: 33.3,
        games: [
          _game(
            name: 'pacman',
            description: 'Pac-Man (Midway)',
            status: 'complete',
            romsChecked: 4,
            romsPresent: 4,
          ),
          _game(
            name: 'mslug',
            description: 'Metal Slug - Super Vehicle-001',
            status: 'missing_bios',
            missingBios: ['neogeo'],
          ),
          _game(
            name: 'kinst',
            description: 'Killer Instinct (v1.5)',
            status: 'incomplete',
            missingRoms: [
              ArcadeMissingEntry(
                kind: 'rom',
                name: 'ki_rom.bin',
                expectedSize: 524288,
                expectedCrc: 'deadbeef',
              ),
            ],
          ),
        ],
      );

  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 900, height: 700, child: child),
        ),
      );

  group('ArcadeAuditView', () {
    testWidgets('renders metric chips and health bar', (tester) async {
      await tester.pumpWidget(
        wrap(ArcadeAuditView(report: sampleReport(), theme: theme)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Total Games'), findsOneWidget);
      expect(find.text('Complete'), findsOneWidget);
      expect(find.text('Missing BIOS'), findsOneWidget);
      expect(find.text('Incomplete'), findsOneWidget);
      expect(find.text('Library health: 33.3%'), findsOneWidget);
    });

    testWidgets('lists every game with its slug and status', (tester) async {
      await tester.pumpWidget(
        wrap(ArcadeAuditView(report: sampleReport(), theme: theme)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pac-Man (Midway)'), findsOneWidget);
      expect(find.text('pacman'), findsOneWidget);
      expect(find.text('Metal Slug - Super Vehicle-001'), findsOneWidget);
      expect(find.text('mslug'), findsOneWidget);
      expect(find.text('Missing BIOS: neogeo.zip'), findsOneWidget);
      expect(find.text('Killer Instinct (v1.5)'), findsOneWidget);
    });

    testWidgets('filters the table when a chip is tapped', (tester) async {
      await tester.pumpWidget(
        wrap(ArcadeAuditView(report: sampleReport(), theme: theme)),
      );
      await tester.pumpAndSettle();

      // Tap the "Complete" metric chip -> only Pac-Man remains.
      await tester.tap(find.text('Complete'));
      await tester.pumpAndSettle();
      expect(find.text('Pac-Man (Midway)'), findsOneWidget);
      expect(find.text('Metal Slug - Super Vehicle-001'), findsNothing);

      // Tap again to clear the filter -> all rows return.
      await tester.tap(find.text('Complete'));
      await tester.pumpAndSettle();
      expect(find.text('Metal Slug - Super Vehicle-001'), findsOneWidget);
    });

    testWidgets('detail dialog shows missing chips with size and CRC',
        (tester) async {
      await tester.pumpWidget(
        wrap(ArcadeAuditView(report: sampleReport(), theme: theme)),
      );
      await tester.pumpAndSettle();

      // Open the incomplete game's details.
      await tester.tap(find.text('Killer Instinct (v1.5)'));
      await tester.pumpAndSettle();

      expect(find.text('Missing / Mismatched ROMs'), findsOneWidget);
      expect(find.text('ki_rom.bin'), findsOneWidget);
      expect(
        find.textContaining('524288 bytes'),
        findsOneWidget,
      );
      expect(find.textContaining('crc deadbeef'), findsOneWidget);
    });

    testWidgets('detail dialog surfaces missing BIOS dependency',
        (tester) async {
      await tester.pumpWidget(
        wrap(ArcadeAuditView(report: sampleReport(), theme: theme)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Metal Slug - Super Vehicle-001'));
      await tester.pumpAndSettle();

      expect(find.text('Missing BIOS'), findsWidgets);
      expect(find.text('neogeo.zip'), findsOneWidget);
    });
  });
}
