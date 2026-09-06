// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3 + Commons Clause

import 'package:flutter_test/flutter_test.dart';
import 'package:openrom_flutter/app.dart';
import 'package:openrom_flutter/services/theme_service.dart';

void main() {
  testWidgets('App loads cleanly test', (WidgetTester tester) async {
    final themeService = ThemeService();
    await tester.pumpWidget(OpenROMApp(themeService: themeService));
    await tester.pump();
    expect(find.text('OpenROM'), findsWidgets);
    await tester.pumpAndSettle();
  });
}
