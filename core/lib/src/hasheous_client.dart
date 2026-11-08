// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// A single game/ROM identification returned by Hasheous.
///
/// Hasheous indexes several preservation databases (Redump, No-Intro, TOSEC,
/// …). One hash lookup can match the same ROM in more than one of them, so a
/// lookup yields a primary [HasheousGameMatch] plus the full list of matches.
class HasheousGameMatch {
  /// Canonical game title (e.g. `Super Mario Bros.`).
  final String gameName;

  /// Name of the matched ROM file as recorded by the source DAT.
  final String romName;

  /// Human-readable platform (e.g. `Nintendo Entertainment System`).
  final String platform;

  /// Region codes derived from the source DAT (e.g. `US`, `Europe`), or null.
  final String? region;

  /// Preservation database the match came from (e.g. `Redump`, `No-Intro`).
  final String sourceDat;

  /// Always true for an instantiated match; the field exists so callers can
  /// pattern-match on a uniform type.
  final bool matched;

  const HasheousGameMatch({
    required this.gameName,
    required this.romName,
    required this.platform,
    required this.sourceDat,
    this.region,
    this.matched = true,
  });

  Map<String, dynamic> toJson() => {
        'game_name': gameName,
        'rom_name': romName,
        'platform': platform,
        'region': region,
        'source_dat': sourceDat,
        'matched': matched,
      };
}

/// Outcome of a Hasheous lookup. Never thrown — network/timeout failures come
/// back as [error] with [matched] false so callers can degrade gracefully.
class HasheousLookupResult {
  /// True when at least one preservation database recognised the hash.
  final bool matched;

  /// The preferred match (best-known database wins), or null when unmatched.
  final HasheousGameMatch? match;

  /// Every match across all databases, in preference order.
  final List<HasheousGameMatch> matches;

  /// Distinct source databases that recognised the hash (e.g. `[Redump]`).
  final List<String> sources;

  /// Informative message when the lookup could not be completed. Null on a
  /// clean success or a clean "not found".
  final String? error;

  const HasheousLookupResult({
    required this.matched,
    this.match,
    this.matches = const [],
    this.sources = const [],
    this.error,
  });

  bool get hasError => error != null;

  factory HasheousLookupResult.notFound() =>
      const HasheousLookupResult(matched: false);

  factory HasheousLookupResult.failure(String message) =>
      HasheousLookupResult(matched: false, error: message);

  Map<String, dynamic> toJson() => {
        'matched': matched,
        if (match != null) 'match': match!.toJson(),
        'matches': matches.map((m) => m.toJson()).toList(),
        'sources': sources,
        if (error != null) 'error': error,
      };
}

/// Thin client for the public, key-free Hasheous hash-lookup API.
///
/// `POST https://hasheous.org/api/v1/Lookup/ByHash?returnAllSources=true&returnFields=All`
/// with a JSON body of the hashes to look up. Any network failure, timeout or
/// malformed response is converted into a [HasheousLookupResult] carrying an
/// [HasheousLookupResult.error] — this class never throws.
class HasheousClient {
  static const String defaultEndpoint =
      'https://hasheous.org/api/v1/Lookup/ByHash';

  /// Databases ranked best-first. A ROM matched in several is reported under
  /// the highest-ranked one so the GUI badge reads "Verified in Redump"
  /// rather than an arbitrary secondary source.
  static const List<String> _sourcePreference = [
    'Redump',
    'No-Intro',
    'No-Intro (Parent-Clone)',
    'TOSEC',
    'FBNeo',
    'MAME',
    'libretro',
    'ScreenScraper',
  ];

  final Uri endpoint;
  final Duration timeout;
  final http.Client _client;

  HasheousClient({
    Uri? endpoint,
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  })  : endpoint = endpoint ?? Uri.parse(defaultEndpoint),
        _client = client ?? http.Client();

  /// Looks up a ROM by any combination of its checksums. At least one of
  /// [sha1], [md5] or [crc] must be supplied.
  Future<HasheousLookupResult> lookupByHash({
    String? sha1,
    String? md5,
    String? crc,
  }) async {
    if ((sha1 == null || sha1.isEmpty) &&
        (md5 == null || md5.isEmpty) &&
        (crc == null || crc.isEmpty)) {
      return HasheousLookupResult.failure('No hash supplied for lookup');
    }

    final uri = endpoint.replace(
      queryParameters: {
        ...endpoint.queryParameters,
        'returnAllSources': 'true',
        'returnFields': 'All',
      },
    );

    final body = jsonEncode({
      if (sha1 != null && sha1.isNotEmpty) 'shA1': sha1,
      if (md5 != null && md5.isNotEmpty) 'mD5': md5,
      if (crc != null && crc.isNotEmpty) 'crc': crc,
    });

    try {
      final response = await _client
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: body,
          )
          .timeout(timeout);

      return _parse(response.statusCode, response.body);
    } on TimeoutException {
      return HasheousLookupResult.failure(
        'Hasheous lookup timed out after ${timeout.inSeconds}s',
      );
    } on http.ClientException catch (e) {
      return HasheousLookupResult.failure('Network error: ${e.message}');
    } on FormatException catch (e) {
      return HasheousLookupResult.failure('Malformed response: ${e.message}');
    } catch (e) {
      return HasheousLookupResult.failure('Lookup failed: $e');
    }
  }

  /// Translates an HTTP status + body into a result. 404 is a clean "no match";
  /// other non-200 statuses become an [HasheousLookupResult.error].
  HasheousLookupResult _parse(int statusCode, String body) {
    if (statusCode == 404) return HasheousLookupResult.notFound();
    if (statusCode != 200) {
      return HasheousLookupResult.failure(
        'Hasheous API returned HTTP $statusCode',
      );
    }

    final dynamic decoded = jsonDecode(body);
    final Map<String, dynamic> data = decoded is List
        ? (decoded.isNotEmpty
            ? Map<String, dynamic>.from(decoded.first as Map)
            : <String, dynamic>{})
        : Map<String, dynamic>.from(decoded as Map);

    final gameName = data['name'] as String? ?? '';
    final platform =
        (data['platform'] as Map?)?['name'] as String? ?? 'Unknown platform';

    final signatures = data['signatures'];
    final matches = <HasheousGameMatch>[];

    if (signatures is Map) {
      for (final entry in signatures.entries) {
        final sourceDat = entry.key.toString();
        final list = entry.value;
        if (list is! List || list.isEmpty) continue;
        final first = list.first;
        if (first is! Map) continue;

        final rom = (first['rom'] as Map?) ?? const {};
        final game = (first['game'] as Map?) ?? const {};

        matches.add(
          HasheousGameMatch(
            gameName: gameName.isNotEmpty
                ? gameName
                : (game['name'] as String? ?? ''),
            romName: rom['name'] as String? ?? game['name'] as String? ?? '',
            platform: platform,
            region: _extractRegion(rom, game),
            sourceDat: sourceDat,
          ),
        );
      }
    }

    if (matches.isEmpty) return HasheousLookupResult.notFound();

    matches.sort((a, b) => _rank(a.sourceDat).compareTo(_rank(b.sourceDat)));
    final sources = <String>[];
    for (final m in matches) {
      if (!sources.contains(m.sourceDat)) sources.add(m.sourceDat);
    }

    return HasheousLookupResult(
      matched: true,
      match: matches.first,
      matches: matches,
      sources: sources,
    );
  }

  static int _rank(String source) {
    final idx = _sourcePreference.indexOf(source);
    return idx == -1 ? _sourcePreference.length : idx;
  }

  /// Pulls region codes from the ROM or game `country` map (keys are codes).
  static String? _extractRegion(Map rom, Map game) {
    for (final map in [rom['country'], game['country'], game['countries']]) {
      if (map is Map && map.isNotEmpty) {
        final keys = map.keys
            .map((k) => k.toString())
            .where((k) => k.isNotEmpty && k != 'ss')
            .toList();
        if (keys.isNotEmpty) return keys.join(', ');
      }
    }
    return null;
  }

  void close() => _client.close();
}
