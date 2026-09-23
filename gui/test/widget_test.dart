// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'package:flutter_test/flutter_test.dart';
import 'package:gui/app.dart';
import 'package:gui/services/theme_service.dart';

void main() {
  testWidgets('App loads cleanly test', (WidgetTester tester) async {
    final themeService = ThemeService();
    await tester.pumpWidget(OpenROMApp(themeService: themeService));
    await tester.pump();
    expect(find.text('OpenROM'), findsWidgets);
    await tester.pumpAndSettle();
  });
}
