// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'package:flutter_test/flutter_test.dart';
import 'package:gui/controllers/home_controller.dart';

void main() {
  test('HomeController initial state', () {
    final controller = HomeController();
    expect(controller.jobs, isEmpty);
    expect(controller.logs, isEmpty);
    expect(controller.isConverting, isFalse);
    expect(controller.showTerminal, isFalse);
    expect(controller.fileCount, equals(0));
  });

  test('HomeController toggle terminal and clear logs', () {
    final controller = HomeController();
    controller.toggleTerminal(true);
    expect(controller.showTerminal, isTrue);

    controller.toggleTerminal(false);
    expect(controller.showTerminal, isFalse);
  });
}
