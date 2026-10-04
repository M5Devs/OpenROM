import 'package:flutter_test/flutter_test.dart';
import 'package:gui/services/update_service.dart';

void main() {
  group('UpdateService version comparison', () {
    test('detects newer major version', () {
      expect(UpdateService.isNewer('4.0.0', '3.7.0'), isTrue);
    });

    test('detects newer minor version', () {
      expect(UpdateService.isNewer('3.8.0', '3.7.0'), isTrue);
    });

    test('detects newer patch version', () {
      expect(UpdateService.isNewer('3.7.1', '3.7.0'), isTrue);
    });

    test('same version is not newer', () {
      expect(UpdateService.isNewer('3.7.0', '3.7.0'), isFalse);
    });

    test('older version is not newer', () {
      expect(UpdateService.isNewer('3.6.0', '3.7.0'), isFalse);
    });
  });
}
