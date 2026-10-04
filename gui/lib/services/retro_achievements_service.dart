// OpenROM — RetroAchievements hash lookup
// M5 Dev | GPL v3

import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class RaHashResult {
  final bool found;
  final int? gameId;
  final String? gameTitle;
  final String? consoleName;
  final String? imageIcon;
  final int? achievementCount;
  final String? gamePageUrl;
  final String hash;
  final String error;

  const RaHashResult({
    this.found = false,
    this.gameId,
    this.gameTitle,
    this.consoleName,
    this.imageIcon,
    this.achievementCount,
    this.gamePageUrl,
    required this.hash,
    this.error = '',
  });
}

class RetroAchievementsService {
  static const String _baseUrl = 'https://retroachievements.org/API';
  static const Duration _timeout = Duration(seconds: 10);

  final String username;
  final String apiKey;

  const RetroAchievementsService({
    required this.username,
    required this.apiKey,
  });

  /// Compute MD5 hash of file at [filePath].
  static Future<String> computeMd5(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    return md5.convert(bytes).toString();
  }

  /// Look up a ROM by its MD5 hash on RetroAchievements.
  /// Returns RaHashResult — never throws.
  Future<RaHashResult> lookupHash(String filePath) async {
    final hash = await computeMd5(filePath);

    try {
      final uri = Uri.parse('$_baseUrl/API_GetGameInfoByMD5.php').replace(
        queryParameters: {
          'z': username,
          'y': apiKey,
          'm': hash,
        },
      );

      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode != 200) {
        return RaHashResult(
          hash: hash,
          error: 'RA API returned ${response.statusCode}',
        );
      }

      final data = jsonDecode(response.body);

      // RA returns 0 or null gameId when hash is not found
      final gameId = data['ID'] as int?;
      if (gameId == null || gameId == 0) {
        return RaHashResult(hash: hash, found: false);
      }

      return RaHashResult(
        found: true,
        hash: hash,
        gameId: gameId,
        gameTitle: data['Title'] as String?,
        consoleName: data['ConsoleName'] as String?,
        imageIcon: data['ImageIcon'] as String?,
        achievementCount: data['NumAchievements'] as int?,
        gamePageUrl: 'https://retroachievements.org/game/$gameId',
      );
    } catch (e) {
      return RaHashResult(hash: hash, error: e.toString());
    }
  }
}
