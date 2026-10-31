// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:openrom_core/openrom_core.dart';

/// Fetches the plugin store registry and downloads verified artifacts.
///
/// Networking lives in the GUI layer so the core package keeps no HTTP
/// dependency. The wire format itself (`StoreManifest`, `StorePlugin`,
/// `StoreChannel`, `StoreArtifact`) is defined in the core package.
class PluginStoreClient {
  final http.Client _client;
  final Uri? _baseUrl;

  PluginStoreClient({http.Client? client, Uri? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl;

  /// Fetches `<baseUrl>/store_manifest.json`. Returns `null` on any failure
  /// (network, non-200, malformed JSON) so callers can fall back gracefully.
  Future<StoreManifest?> fetchManifest({
    Uri? baseUrl,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final base = baseUrl ?? _baseUrl;
    if (base == null) return null;
    try {
      final response = await _client.get(base.resolve('store_manifest.json')).timeout(timeout);
      if (response.statusCode != 200) return null;
      return StoreManifest.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  /// Downloads a plugin artifact and verifies its SHA-256 against the digest
  /// published in the registry. Returns `null` when the download fails or the
  /// digest mismatches — callers must treat `null` as a hard failure and never
  /// fall back to trusting unverified bytes.
  Future<List<int>?> downloadArtifact(
    StoreArtifact artifact, {
    Duration timeout = const Duration(seconds: 120),
  }) async {
    if (artifact.url.isEmpty || artifact.sha256.isEmpty) return null;
    try {
      final response =
          await _client.get(Uri.parse(artifact.url)).timeout(timeout);
      if (response.statusCode != 200) return null;
      final bytes = response.bodyBytes;
      final digest = sha256.convert(bytes).toString().toLowerCase();
      if (digest != artifact.sha256.trim().toLowerCase()) return null;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  void close() => _client.close();
}
