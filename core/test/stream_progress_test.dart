import 'dart:async';
import 'dart:convert';
import 'package:openrom_core/openrom_core.dart';
import 'package:test/test.dart';

void main() {
  group('Stream Progress Parser', () {
    test('processStreamLines emits lines separated by carriage return \\r',
        () async {
      final controller = StreamController<List<int>>();
      final receivedLines = <String>[];

      final future = processStreamLines(controller.stream, (line) {
        receivedLines.add(line);
      });

      // Simulate chdman emitting real-time percentage progress with \r
      controller.add(utf8.encode("Compressing, 10.5% complete...\r"));
      controller.add(utf8.encode("Compressing, 45.2% complete...\r"));
      controller.add(utf8.encode("Compressing, 100.0% complete...\r\n"));

      await controller.close();
      await future;

      expect(receivedLines, contains("Compressing, 10.5% complete..."));
      expect(receivedLines, contains("Compressing, 45.2% complete..."));
      expect(receivedLines, contains("Compressing, 100.0% complete..."));
    });

    test('processStreamLines handles split chunks across carriage return',
        () async {
      final controller = StreamController<List<int>>();
      final receivedLines = <String>[];

      final future = processStreamLines(controller.stream, (line) {
        receivedLines.add(line);
      });

      // Split across two chunks
      controller.add(utf8.encode("Compressing, 2"));
      controller.add(utf8.encode("5.0% complete...\rCompressing, 50.0%"));
      controller.add(utf8.encode(" complete...\r"));

      await controller.close();
      await future;

      expect(receivedLines, contains("Compressing, 25.0% complete..."));
      expect(receivedLines, contains("Compressing, 50.0% complete..."));
    });
  });
}
