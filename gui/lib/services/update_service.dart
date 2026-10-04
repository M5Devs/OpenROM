// OpenROM — GitHub release update checker
// M5 Dev | GPL v3

import 'dart:convert';
import 'package:http/http.dart' as http;

class UpdateCheckResult {
  final bool hasUpdate;
  final String? latestVersion;
  final String? releaseUrl;
  final String? releaseNotes;
  final String error;

  const UpdateCheckResult({
    this.hasUpdate = false,
    this.latestVersion,
    this.releaseUrl,
    this.releaseNotes,
    this.error = '',
  });
}

class UpdateService {
  static const String _repoApi =
      'https://api.github.com/repos/M5Devs/OpenROM/releases/latest';
  static const Duration _timeout = Duration(seconds: 10);

  /// Checks GitHub releases for a newer version.
  /// Returns UpdateCheckResult — never throws.
  /// [currentVersion] should be like "3.7.0" (no "v" prefix).
  static Future<UpdateCheckResult> checkForUpdate(
      String currentVersion) async {
    try {
      final response = await http
          .get(
            Uri.parse(_repoApi),
            headers: {'Accept': 'application/vnd.github+json'},
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        return UpdateCheckResult(
          error: 'GitHub API returned ${response.statusCode}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = (data['tag_name'] as String? ?? '').replaceFirst('v', '');
      final htmlUrl = data['html_url'] as String? ?? '';
      final body = data['body'] as String? ?? '';

      final hasUpdate = isNewer(tagName, currentVersion);

      return UpdateCheckResult(
        hasUpdate: hasUpdate,
        latestVersion: tagName,
        releaseUrl: htmlUrl,
        releaseNotes: body,
      );
    } catch (e) {
      return UpdateCheckResult(error: e.toString());
    }
  }

  /// Returns true if [remote] is a higher semver than [current].
  static bool isNewer(String remote, String current) {
    try {
      final r = remote.split('.').map(int.parse).toList();
      final c = current.split('.').map(int.parse).toList();
      for (var i = 0; i < 3; i++) {
        final rv = i < r.length ? r[i] : 0;
        final cv = i < c.length ? c[i] : 0;
        if (rv > cv) return true;
        if (rv < cv) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
