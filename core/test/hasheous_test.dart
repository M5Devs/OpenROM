// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:openrom_core/openrom_core.dart';
import 'package:test/test.dart';

/// A [http.BaseClient] that returns a canned response without touching the
/// network, and records the last request so tests can assert on the wire format.
class _MockClient extends http.BaseClient {
  final Future<http.Response> Function(http.BaseRequest request) handler;
  http.BaseRequest? lastRequest;
  String? lastBody;

  _MockClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastRequest = request;
    if (request is http.Request) lastBody = request.body;
    final response = await handler(request);
    return http.StreamedResponse(
      Stream.value(utf8.encode(response.body)),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }
}

/// Minimal, real-shaped Hasheous success payload (trimmed from the live API).
const _successBody = '''
{
  "id": 264,
  "name": "Super Mario Bros.",
  "platform": { "name": "Nintendo Entertainment System" },
  "publisher": { "name": "Nintendo" },
  "signatures": {
    "TOSEC": [
      {
        "game": {
          "name": "Super Mario Bros.",
          "system": "Nintendo Famicom & Entertainment System",
          "country": { "JP": "Japan", "US": "United States" }
        },
        "rom": {
          "name": "Super Mario Bros. (1985-09-13)(Nintendo)(JP-US).nes",
          "crc": "3337ec46",
          "md5": "811b027eaf99c2def7b933c5208636de"
        }
      }
    ],
    "libretro": [
      {
        "game": { "name": "Super Mario Bros." },
        "rom": {
          "name": "Super Mario Bros. (1985-09-13)(Nintendo)(JP-US).nes",
          "sha1": "ea343f4e445a9050d4b4fbac2c77d0693b1d0922"
        }
      }
    ]
  }
}
''';

void main() {
  const sha1 = 'ea343f4e445a9050d4b4fbac2c77d0693b1d0922';
  const md5Hex = '811b027eaf99c2def7b933c5208636de';
  const crc = '3337EC46';

  group('HasheousClient successful match', () {
    test('parses a 200 response into a typed match', () async {
      final mock = _MockClient(
        (_) async => http.Response(_successBody, 200,
            headers: {'content-type': 'application/json'}),
      );
      final client = HasheousClient(client: mock);

      final result = await client.lookupByHash(sha1: sha1, md5: md5Hex, crc: crc);

      expect(result.matched, isTrue);
      expect(result.error, isNull);
      expect(result.match, isNotNull);

      final m = result.match!;
      expect(m.gameName, 'Super Mario Bros.');
      expect(m.platform, 'Nintendo Entertainment System');
      expect(m.sourceDat, 'TOSEC');
      expect(m.matched, isTrue);
      expect(m.region, contains('US'));
      expect(m.romName, contains('Super Mario Bros.'));

      // Both databases are surfaced, best-first (TOSEC ranks above libretro).
      expect(result.sources, containsAll(<String>['TOSEC', 'libretro']));
      expect(result.sources.first, 'TOSEC');
    });

    test('sends the hashes in the documented wire format', () async {
      final mock = _MockClient((_) async => http.Response(_successBody, 200));
      final client = HasheousClient(client: mock);

      await client.lookupByHash(sha1: sha1, md5: md5Hex, crc: crc);

      final sent = jsonDecode(mock.lastBody!) as Map<String, dynamic>;
      expect(sent['shA1'], sha1);
      expect(sent['mD5'], md5Hex);
      expect(sent['crc'], crc);

      final req = mock.lastRequest!;
      expect(req.method, 'POST');
      expect(req.headers['Content-Type'], 'application/json');
      expect(req.headers['Accept'], 'application/json');
      expect(req.url.queryParameters['returnAllSources'], 'true');
      expect(req.url.queryParameters['returnFields'], 'All');
    });

    test('omits hashes that were not supplied', () async {
      final mock = _MockClient((_) async => http.Response(_successBody, 200));
      final client = HasheousClient(client: mock);

      await client.lookupByHash(sha1: sha1);

      final sent = jsonDecode(mock.lastBody!) as Map<String, dynamic>;
      expect(sent.containsKey('shA1'), isTrue);
      expect(sent.containsKey('mD5'), isFalse);
      expect(sent.containsKey('crc'), isFalse);
    });

    test('toJson round-trips the match fields', () async {
      final mock = _MockClient((_) async => http.Response(_successBody, 200));
      final result =
          await HasheousClient(client: mock).lookupByHash(sha1: sha1);
      final json = result.toJson();
      expect(json['matched'], isTrue);
      expect((json['match'] as Map)['source_dat'], 'TOSEC');
      expect(json['sources'], isA<List>());
    });
  });

  group('HasheousClient unmatched', () {
    test('treats 404 as a clean no-match (not an error)', () async {
      final mock = _MockClient(
        (_) async => http.Response(
          '"The provided hash was not found in any signature database."',
          404,
        ),
      );
      final result =
          await HasheousClient(client: mock).lookupByHash(sha1: sha1);

      expect(result.matched, isFalse);
      expect(result.hasError, isFalse);
      expect(result.error, isNull);
      expect(result.match, isNull);
      expect(result.matches, isEmpty);
    });

    test('treats a 200 with no signatures as a no-match', () async {
      final mock = _MockClient(
        (_) async => http.Response('{"id":1,"name":"?","signatures":{}}', 200),
      );
      final result =
          await HasheousClient(client: mock).lookupByHash(md5: md5Hex);
      expect(result.matched, isFalse);
      expect(result.hasError, isFalse);
    });

    test('rejects a lookup with no hashes at all', () async {
      final mock = _MockClient((_) async => http.Response('{}', 200));
      final result = await HasheousClient(client: mock).lookupByHash();
      expect(result.matched, isFalse);
      expect(result.hasError, isTrue);
      expect(result.error, contains('No hash'));
    });
  });

  group('HasheousClient failure handling', () {
    test('times out gracefully', () async {
      final mock = _MockClient((_) async {
        // Never completes before the client's timeout fires.
        await Future<void>.delayed(const Duration(seconds: 5));
        return http.Response(_successBody, 200);
      });
      final client = HasheousClient(
        client: mock,
        timeout: const Duration(milliseconds: 50),
      );

      final result = await client.lookupByHash(sha1: sha1);

      expect(result.matched, isFalse);
      expect(result.hasError, isTrue);
      expect(result.error, contains('timed out'));
    });

    test('reports a socket/network failure without throwing', () async {
      final mock = _MockClient(
        (_) async => throw http.ClientException('Connection refused'),
      );
      final result =
          await HasheousClient(client: mock).lookupByHash(sha1: sha1);

      expect(result.matched, isFalse);
      expect(result.hasError, isTrue);
      expect(result.error, contains('Network error'));
    });

    test('reports an unexpected 500 as an error', () async {
      final mock = _MockClient((_) async => http.Response('oops', 500));
      final result =
          await HasheousClient(client: mock).lookupByHash(sha1: sha1);

      expect(result.matched, isFalse);
      expect(result.hasError, isTrue);
      expect(result.error, contains('HTTP 500'));
    });

    test('reports malformed JSON as an error', () async {
      final mock = _MockClient((_) async => http.Response('<html>', 200));
      final result =
          await HasheousClient(client: mock).lookupByHash(sha1: sha1);

      expect(result.matched, isFalse);
      expect(result.hasError, isTrue);
      expect(result.error, isNotNull);
    });
  });
}
