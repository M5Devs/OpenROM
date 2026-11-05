// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'plugin/plugin_manifest.dart';

/// The action an `openrom://` link asks the app to perform.
enum DeepLinkAction {
  /// Open the store page / detail view for a plugin.
  plugin,

  /// Jump straight to installing a plugin.
  install,
}

/// A parsed `openrom://` deep link.
///
/// Recognised forms (host and action are case-insensitive):
///  * `openrom://plugin/<id>`
///  * `openrom://install/<id>`
///  * `openrom:plugin/<id>` (no authority)
///  * `openrom://plugin?id=<id>` (query form)
class DeepLinkTarget {
  final DeepLinkAction action;
  final String id;

  /// The original, unmodified link (useful for logging and diagnostics).
  final String raw;

  const DeepLinkTarget({
    required this.action,
    required this.id,
    required this.raw,
  });

  Map<String, dynamic> toJson() => {
        'action': action.name,
        'id': id,
      };

  @override
  String toString() => 'DeepLinkTarget(${action.name}, $id)';
}

/// Parses `openrom://` links. Pure and side-effect free so it is trivially
/// testable and can be reused by the CLI, the GUI and native handlers.
abstract final class DeepLink {
  static const String scheme = 'openrom';

  static const Map<String, DeepLinkAction> _actions = {
    'plugin': DeepLinkAction.plugin,
    'install': DeepLinkAction.install,
  };

  /// Parses [raw] into a [DeepLinkTarget], or returns `null` when it is not a
  /// well-formed `openrom://` link with a valid plugin id.
  static DeepLinkTarget? parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.scheme.toLowerCase() != scheme) return null;

    // `Uri` silently collapses `..` segments, so `openrom://install/../evil`
    // would otherwise resolve to the id `evil`. Reject traversal outright —
    // a plugin id is a flat lookup key and must never look like a path.
    if (trimmed.contains('..')) return null;

    // `openrom://plugin/abc` → host=plugin, pathSegments=[abc]
    // `openrom:plugin/abc`    → host='',     pathSegments=[plugin, abc]
    final segments = <String>[
      if (uri.host.isNotEmpty) uri.host,
      ...uri.pathSegments,
    ].where((s) => s.isNotEmpty).toList();

    if (segments.isEmpty) return null;

    final action = _actions[segments.first.toLowerCase()];
    if (action == null) return null;

    var id = segments.length > 1 ? segments[1] : '';
    if (id.isEmpty) id = uri.queryParameters['id']?.trim() ?? '';
    if (id.isEmpty || !kPluginIdPattern.hasMatch(id)) return null;

    return DeepLinkTarget(action: action, id: id, raw: trimmed);
  }

  /// Returns the first argument that parses as an `openrom://` link.
  ///
  /// Native launchers hand the URL to the process either as a bare argument or
  /// wrapped in quotes, so both are accepted.
  static DeepLinkTarget? fromArguments(Iterable<String> args) {
    for (final arg in args) {
      final target = parse(_stripQuotes(arg));
      if (target != null) return target;
    }
    return null;
  }

  static String _stripQuotes(String value) {
    var v = value.trim();
    if (v.length >= 2 &&
        (v.startsWith('"') && v.endsWith('"') ||
            v.startsWith("'") && v.endsWith("'"))) {
      v = v.substring(1, v.length - 1);
    }
    return v;
  }
}
