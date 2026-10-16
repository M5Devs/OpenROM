// OpenROM — Responsive Layout Widget Tests
// M5 Dev | GPL v3

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gui/app.dart';
import 'package:gui/services/theme_service.dart';

void main() {
  testWidgets('Renders BottomNavigationBar on narrow screen (< 650px)',
      (tester) async {
    tester.view.physicalSize = const Size(500, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final themeService = ThemeService();
    await tester.pumpWidget(OpenROMApp(themeService: themeService));
    await tester.pumpAndSettle();

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Convert'), findsOneWidget);
    expect(find.text('Patch'), findsOneWidget);
    expect(find.text('Tools'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Tap Patch tab with warnIfMissed false for BottomNavigationBar item taps
    await tester.tap(find.text('Patch'), warnIfMissed: false);
    await tester.pumpAndSettle();

    // Tap Settings tab
    await tester.tap(find.text('Settings'), warnIfMissed: false);
    await tester.pumpAndSettle();
  });
}
