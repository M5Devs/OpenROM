// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'plugin_version.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// Dynamic store contract (pure models — no networking).
///
/// The registry publishes a single `store_manifest.json`. It lists trusted
/// publishers and the plugins they publish, each with per-platform artifacts
/// and their SHA-256 digests. Those digests are the root of trust: the
/// installer verifies a downloaded archive against the digest read from the
/// registry *before* unpacking it.
///
/// Network fetching lives in the GUI layer (`PluginStoreClient` in
/// `gui/lib/services/plugin_store_client.dart`) so the core package stays free
/// of an HTTP dependency. This file only defines the wire format.
///
/// ```json
/// {
///   "schemaVersion": 1,
///   "publishers": [
///     { "id": "m5dev", "name": "M5 Dev", "verified": true, "url": "https://…" }
///   ],
///   "plugins": [
///     {
///       "id": "xbox360-tools",
///       "name": "Xbox 360 Tools",
///       "description": "…",
///       "publisherId": "m5dev",
///       "tags": ["xbox360", "iso"],
///       "channels": {
///         "stable": {
///           "version": "1.2.0",
///           "minCoreVersion": "3.9.0",
///           "artifacts": {
///             "windows_x64": { "url": "https://…/x.orplug", "sha256": "…", "size": 12345 }
///           }
///         }
///       }
///     }
///   ]
/// }
/// ```
/// ─────────────────────────────────────────────────────────────────────────

/// A single downloadable artifact (one platform, one channel).
class StoreArtifact {
  final String url;
  final String sha256;
  final int size;

  const StoreArtifact({
    required this.url,
    required this.sha256,
    this.size = 0,
  });

  factory StoreArtifact.fromJson(Map<String, dynamic> json) => StoreArtifact(
        url: json['url'] as String? ?? '',
        sha256: json['sha256'] as String? ?? '',
        size: (json['size'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'url': url,
        'sha256': sha256,
        'size': size,
      };

  bool get isWellFormed =>
      url.trim().isNotEmpty &&
      RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(sha256.trim());
}

/// One release channel (e.g. `stable`, `beta`) for a plugin.
class StoreChannel {
  final String channel;
  final String version;
  final String? minCoreVersion;
  final Map<String, StoreArtifact> artifacts;

  const StoreChannel({
    required this.channel,
    required this.version,
    this.minCoreVersion,
    this.artifacts = const {},
  });

  factory StoreChannel.fromJson(String channel, Map<String, dynamic> json) {
    final rawArtifacts = json['artifacts'] as Map<String, dynamic>? ?? {};
    return StoreChannel(
      channel: channel,
      version: json['version'] as String? ?? '',
      minCoreVersion: json['minCoreVersion'] as String?,
      artifacts: rawArtifacts.map(
        (k, v) => MapEntry(
            k, StoreArtifact.fromJson(v as Map<String, dynamic>? ?? {})),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        if (minCoreVersion != null) 'minCoreVersion': minCoreVersion,
        'artifacts': artifacts.map((k, v) => MapEntry(k, v.toJson())),
      };

  SemVer? get semver => SemVer.tryParse(version);
  SemVer? get minCoreSemver => SemVer.tryParseLoose(minCoreVersion);

  /// The artifact for [platformKey] in this channel, if published.
  StoreArtifact? artifactFor(String platformKey) => artifacts[platformKey];
}

/// A publisher as advertised by the registry.
class StorePublisher {
  final String id;
  final String name;
  final bool verified;
  final String url;

  const StorePublisher({
    required this.id,
    required this.name,
    this.verified = false,
    this.url = '',
  });

  factory StorePublisher.fromJson(Map<String, dynamic> json) => StorePublisher(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        verified: json['verified'] as bool? ?? false,
        url: json['url'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'verified': verified,
        'url': url,
      };
}

/// A plugin listing in the store, resolved against its publisher.
class StorePlugin {
  final String id;
  final String name;
  final String description;
  final StorePublisher publisher;
  final List<String> tags;
  final Map<String, StoreChannel> channels;

  const StorePlugin({
    required this.id,
    required this.name,
    required this.description,
    required this.publisher,
    this.tags = const [],
    this.channels = const {},
  });

  factory StorePlugin.fromJson(
    Map<String, dynamic> json,
    Map<String, StorePublisher> publishers,
  ) {
    final publisherId = json['publisherId'] as String? ?? '';
    final publisher = publishers[publisherId] ??
        StorePublisher(id: publisherId, name: publisherId);

    final rawChannels = json['channels'] as Map<String, dynamic>? ?? {};
    final channels = rawChannels.map(
      (k, v) => MapEntry(
          k, StoreChannel.fromJson(k, v as Map<String, dynamic>? ?? {})),
    );

    final rawTags = json['tags'] as List<dynamic>? ?? [];

    return StorePlugin(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      publisher: publisher,
      tags: rawTags.map((e) => e.toString()).toList(),
      channels: channels,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'publisherId': publisher.id,
        'tags': tags,
        'channels': channels.map((k, v) => MapEntry(k, v.toJson())),
      };

  /// Preferred channel lookup with a graceful fallback to `stable`.
  StoreChannel? channel(String name) => channels[name] ?? channels['stable'];

  /// The latest version across all channels (by SemVer).
  String get latestVersion {
    SemVer? best;
    for (final c in channels.values) {
      final v = c.semver;
      if (v == null) continue;
      if (best == null || v > best) best = v;
    }
    return best?.toString() ?? '';
  }

  // Convenience display fields mirroring the legacy flat store model.
  String get author => publisher.name;
  bool get isVerified => publisher.verified;
  String get version => channel('stable')?.version ?? latestVersion;
}

/// The whole registry document.
class StoreManifest {
  final int schemaVersion;
  final List<StorePublisher> publishers;
  final List<StorePlugin> plugins;

  const StoreManifest({
    this.schemaVersion = 1,
    this.publishers = const [],
    this.plugins = const [],
  });

  factory StoreManifest.fromJson(Map<String, dynamic> json) {
    final rawPublishers = json['publishers'] as List<dynamic>? ?? [];
    final publishers = rawPublishers
        .whereType<Map<String, dynamic>>()
        .map(StorePublisher.fromJson)
        .toList();

    final byId = {for (final pub in publishers) pub.id: pub};

    final rawPlugins = json['plugins'] as List<dynamic>? ?? [];
    final plugins = rawPlugins
        .whereType<Map<String, dynamic>>()
        .map((e) => StorePlugin.fromJson(e, byId))
        .toList();

    return StoreManifest(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      publishers: publishers,
      plugins: plugins,
    );
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'publishers': publishers.map((p) => p.toJson()).toList(),
        'plugins': plugins.map((p) => p.toJson()).toList(),
      };

  StorePlugin? pluginById(String id) {
    for (final plugin in plugins) {
      if (plugin.id == id) return plugin;
    }
    return null;
  }
}
