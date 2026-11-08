// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gui/widgets/hasheous_result_card.dart';
import 'package:openrom_core/openrom_core.dart'
    show HasheousGameMatch, HasheousLookupResult;

void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );

  group('HasheousResultCard', () {
    const match = HasheousGameMatch(
      gameName: 'Super Mario Bros.',
      romName: 'Super Mario Bros. (1985)(Nintendo)(JP-US).nes',
      platform: 'Nintendo Entertainment System',
      region: 'US',
      sourceDat: 'Redump',
    );

    testWidgets('shows the game title, platform/region and verified badge',
        (tester) async {
      await tester.pumpWidget(wrap(const HasheousResultCard(match: match)));

      expect(find.text('Super Mario Bros.'), findsOneWidget);
      expect(
        find.text('Nintendo Entertainment System · US'),
        findsOneWidget,
      );
      expect(find.text('Verified in Redump'), findsOneWidget);
      expect(find.byIcon(Icons.verified), findsOneWidget);
    });

    testWidgets('lists additional sources when more than one matched',
        (tester) async {
      await tester.pumpWidget(wrap(const HasheousResultCard(
        match: match,
        sources: ['Redump', 'TOSEC', 'libretro'],
      )));

      expect(find.text('+ 2 more'), findsOneWidget);
    });

    testWidgets('fromLookup renders the card on a match', (tester) async {
      const lookup = HasheousLookupResult(
        matched: true,
        match: match,
        sources: ['Redump'],
      );
      await tester.pumpWidget(wrap(
        Builder(builder: (ctx) => HasheousResultCard.fromLookup(ctx, lookup)),
      ));

      expect(find.text('Super Mario Bros.'), findsOneWidget);
      expect(find.text('Verified in Redump'), findsOneWidget);
    });
  });

  group('Hasheous banners', () {
    testWidgets('no-match banner shows the gentle message', (tester) async {
      await tester.pumpWidget(wrap(const HasheousNoMatchBanner()));
      expect(
        find.text('No match found in preservation databases.'),
        findsOneWidget,
      );
    });

    testWidgets('error banner surfaces the offline reason', (tester) async {
      await tester.pumpWidget(
        wrap(const HasheousErrorBanner(message: 'Network error: offline')),
      );
      expect(
        find.text('Identification unavailable: Network error: offline'),
        findsOneWidget,
      );
    });

    testWidgets('fromLookup renders the no-match banner when unmatched',
        (tester) async {
      const lookup = HasheousLookupResult(matched: false);
      await tester.pumpWidget(wrap(
        Builder(builder: (ctx) => HasheousResultCard.fromLookup(ctx, lookup)),
      ));
      expect(
        find.text('No match found in preservation databases.'),
        findsOneWidget,
      );
    });

    testWidgets('fromLookup renders the error banner on failure',
        (tester) async {
      final lookup = HasheousLookupResult.failure('Lookup timed out');
      await tester.pumpWidget(wrap(
        Builder(builder: (ctx) => HasheousResultCard.fromLookup(ctx, lookup)),
      ));
      expect(
        find.textContaining('Identification unavailable'),
        findsOneWidget,
      );
    });
  });
}
