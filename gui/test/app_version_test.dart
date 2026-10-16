// OpenROM — AppVersion Unit Tests
// M5 Dev | GPL v3

import 'package:flutter_test/flutter_test.dart';
import 'package:gui/utils/app_version.dart';

void main() {
  group('AppVersion Tests', () {
    test('AppVersion.current returns dynamic current version string', () {
      final version = AppVersion.current;
      expect(version, isNotEmpty);
      expect(version, equals('3.9.0'));
    });
  });
}
