// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'plugin_store.dart';

/// The storefront categories, mirroring the web store at
/// `https://openrom-store.pages.dev`. Order is significant: it drives the
/// filter chip order in the GUI.
const List<String> kStoreCategories = [
  'Nintendo',
  'Sega',
  'PlayStation',
  'Xbox',
  'Utility',
  'Patchers',
];

/// A single listing from the live catalogue API (`/api/plugins.json`).
///
/// This is the *flat* wire format served by the Cloudflare D1 store, which is
/// deliberately simpler than the multi-channel [StoreManifest]: one row per
/// plugin, one artifact per row. [toStorePlugin] adapts it to the channel-based
/// model the installer already understands.
class StoreListing {
  final String id;
  final String name;
  final String version;
  final String? minCoreVersion;
  final String publisherId;
  final String publisherName;
  final bool publisherVerified;
  final String category;
  final String description;
  final String readme;
  final List<String> routes;
  final List<String> platforms;

  /// Direct download URL for the `.orplug` artifact (SourceForge).
  final String downloadUrl;

  /// Lowercase hex SHA-256 of the artifact, the root of trust for installs.
  final String sha256;

  /// Icon identifier (e.g. `gamepad`); the GUI maps it to a Material icon.
  final String icon;
  final int downloads;
  final String createdAt;

  const StoreListing({
    required this.id,
    required this.name,
    required this.version,
    this.minCoreVersion,
    this.publisherId = '',
    this.publisherName = '',
    this.publisherVerified = false,
    this.category = 'Utility',
    this.description = '',
    this.readme = '',
    this.routes = const [],
    this.platforms = const [],
    this.downloadUrl = '',
    this.sha256 = '',
    this.icon = '',
    this.downloads = 0,
    this.createdAt = '',
  });

  factory StoreListing.fromJson(Map<String, dynamic> json) {
    final publisherId = json['publisherId'] as String? ?? '';
    final publisherName = json['publisherName'] as String? ?? '';
    return StoreListing(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      version: json['version'] as String? ?? '',
      minCoreVersion: json['minCoreVersion'] as String?,
      publisherId: publisherId,
      publisherName: publisherName.isEmpty ? publisherId : publisherName,
      publisherVerified: json['publisherVerified'] as bool? ?? false,
      category: json['category'] as String? ?? 'Utility',
      description: json['description'] as String? ?? '',
      readme: json['readme'] as String? ?? '',
      routes: _stringList(json['routes']),
      platforms: _stringList(json['platforms']),
      // The API camel-cases it as `downloadUrl`; tolerate the snake_case form
      // used by some registry exports.
      downloadUrl:
          (json['downloadUrl'] ?? json['download_url']) as String? ?? '',
      sha256: json['sha256'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      downloads: (json['downloads'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'version': version,
        if (minCoreVersion != null) 'minCoreVersion': minCoreVersion,
        'publisherId': publisherId,
        'publisherName': publisherName,
        'publisherVerified': publisherVerified,
        'category': category,
        'description': description,
        if (readme.isNotEmpty) 'readme': readme,
        'routes': routes,
        'platforms': platforms,
        'downloadUrl': downloadUrl,
        'sha256': sha256,
        'icon': icon,
        'downloads': downloads,
        if (createdAt.isNotEmpty) 'createdAt': createdAt,
      };

  /// Decodes the array served at `/api/plugins.json`. Entries that are not
  /// JSON objects are skipped rather than failing the whole catalogue.
  static List<StoreListing> listFromJson(dynamic decoded) {
    final raw = decoded is List
        ? decoded
        : (decoded is Map<String, dynamic> ? decoded['plugins'] : null);
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(StoreListing.fromJson)
        .toList();
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((e) => e.toString()).toList();
  }

  /// Adapts this listing to the channel-based [StorePlugin] model so the
  /// existing install path (download → verify → `PluginManager.installPlugin`)
  /// can be reused unchanged.
  ///
  /// The digest is attached to *every* platform key because the storefront
  /// publishes a single universal `.orplug` archive. The installer then picks
  /// the key matching the host.
  StorePlugin toStorePlugin() {
    final artifact = StoreArtifact(
      url: downloadUrl,
      sha256: sha256,
      size: 0,
    );
    final artifacts = <String, StoreArtifact>{
      for (final key in const [
        'windows_x64',
        'windows_arm64',
        'linux_x64',
        'linux_arm64',
        'macos_x64',
        'macos_arm64',
      ])
        key: artifact,
    };

    return StorePlugin(
      id: id,
      name: name,
      description: description,
      publisher: StorePublisher(
        id: publisherId,
        name: publisherName.isEmpty ? publisherId : publisherName,
        verified: publisherVerified,
      ),
      tags: routes,
      channels: {
        'stable': StoreChannel(
          channel: 'stable',
          version: version,
          minCoreVersion: minCoreVersion,
          artifacts: artifacts,
        ),
      },
    );
  }
}
