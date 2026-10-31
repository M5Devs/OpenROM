// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'package:openrom_core/openrom_core.dart';

import 'plugin_store_client.dart';

/// Result of a store-driven installation, carrying a precise failure reason.
class StoreInstallOutcome {
  final bool success;
  final String? error;

  const StoreInstallOutcome.success()
      : success = true,
        error = null;

  const StoreInstallOutcome.failure(this.error) : success = false;
}

class PluginService {
  final PluginManager _pluginManager;
  final PluginStoreClient _storeClient;

  /// Default registry endpoint. The store is entirely optional; when it is
  /// unreachable the app falls back to the bundled catalogue.
  static const String defaultRegistryUrl =
      'https://plugins.openrom.dev/registry';

  PluginService({
    PluginManager? pluginManager,
    PluginStoreClient? storeClient,
  })  : _pluginManager = pluginManager ?? PluginManager.instance,
        _storeClient = storeClient ?? PluginStoreClient();

  /// Loads all installed plugins and returns active manifests.
  Future<List<PluginManifest>> loadInstalledPlugins() async {
    await _pluginManager.loadInstalledPlugins();
    return _pluginManager.installedPlugins;
  }

  /// Installs a plugin from a local `.orplug` ZIP archive path.
  Future<bool> installPlugin(String orplugPath) async {
    return await _pluginManager.installPlugin(orplugPath);
  }

  /// Installs a plugin and returns the full result (manifest or error).
  Future<PluginInstallResult> installPluginDetailed(String orplugPath) async {
    return await _pluginManager.installPluginDetailed(orplugPath);
  }

  /// Uninstalls a plugin by its ID.
  Future<bool> uninstallPlugin(String pluginId) async {
    return await _pluginManager.uninstallPlugin(pluginId);
  }

  /// Fetches the store registry document from [endpointUrl] (or the default).
  /// Returns `null` when the registry is unreachable.
  Future<StoreManifest?> fetchStoreManifest({String? endpointUrl}) async {
    final url = (endpointUrl != null && endpointUrl.isNotEmpty)
        ? endpointUrl
        : defaultRegistryUrl;
    return _storeClient.fetchManifest(baseUrl: Uri.tryParse(url));
  }

  /// Fetches available plugins for the store catalogue.
  ///
  /// Tries the registry first; on any failure returns the bundled default
  /// catalogue so the UI is never empty.
  Future<List<StorePlugin>> fetchStoreCatalog({String? endpointUrl}) async {
    final manifest = await fetchStoreManifest(endpointUrl: endpointUrl);
    if (manifest != null && manifest.plugins.isNotEmpty) {
      return manifest.plugins;
    }
    return _defaultStoreCatalog;
  }

  /// Downloads and installs a plugin listed in the store.
  ///
  /// The artifact is verified against the registry's SHA-256 before it is
  /// handed to the installer, and the installer additionally pins the id and
  /// version so a tampered archive cannot masquerade as another plugin.
  Future<StoreInstallOutcome> installFromStore(
    StorePlugin plugin, {
    String channel = 'stable',
  }) async {
    final selected = plugin.channel(channel);
    if (selected == null) {
      return StoreInstallOutcome.failure(
        'Plugin "${plugin.id}" has no "$channel" channel.',
      );
    }

    final artifact = selected.artifactFor(currentPlatformKey());
    if (artifact == null) {
      return StoreInstallOutcome.failure(
        'Plugin "${plugin.id}" has no build for platform '
        '"${currentPlatformKey()}".',
      );
    }
    if (!artifact.isWellFormed) {
      return StoreInstallOutcome.failure(
        'Plugin "${plugin.id}" published a malformed artifact entry.',
      );
    }

    final bytes = await _storeClient.downloadArtifact(artifact);
    if (bytes == null) {
      return const StoreInstallOutcome.failure(
        'Download failed or the artifact failed checksum verification.',
      );
    }

    final result = await _pluginManager.installPluginFromBytes(
      bytes,
      expectedSha256: artifact.sha256,
      expectedId: plugin.id,
      expectedVersion: selected.semver,
    );

    return result.success
        ? const StoreInstallOutcome.success()
        : StoreInstallOutcome.failure(result.error);
  }

  /// Bundled fallback catalogue used when the registry is unreachable.
  static final List<StorePlugin> _defaultStoreCatalog = [
    _defaultEntry(
      id: 'xgdtool_360',
      name: 'Xbox 360 XGDTool Engine',
      version: '1.2.0',
      publisher: _m5dev,
      description:
          'Adds full conversion support for Xbox 360 compressed disc formats (.zar, .cci) to standard ISO.',
      tags: ['.zar', '.cci', '.iso'],
    ),
    _defaultEntry(
      id: 'saturn_ssp',
      name: 'Sega Saturn SSP Patcher',
      version: '1.0.4',
      publisher: _m5dev,
      description:
          'Enables native creation and application of Sega Saturn SSP patch files with Mode-1 EDC/ECC recalculation.',
      tags: ['.ssp', '.iso'],
    ),
    _defaultEntry(
      id: 'nkit_gc_wii',
      name: 'NKit GameCube & Wii Suite',
      version: '2.1.0',
      publisher: _m5dev,
      description:
          'Supports raw disc image restoration and conversion for NKit (.nkit.iso, .wud, .wux, .wua) formats.',
      tags: ['.nkit.iso', '.wud', '.wux', '.wua'],
    ),
    _defaultEntry(
      id: 'ps2_gz_compressor',
      name: 'PS2 GZ ISO Tool',
      version: '0.8.2',
      publisher: const StorePublisher(
          id: 'retrocommunity', name: 'RetroCommunity', verified: false),
      description:
          'Fast block gzip compression and decompression plugin for PlayStation 2 DVD ISOs.',
      tags: ['.gz', '.iso'],
    ),
    _defaultEntry(
      id: 'chd_lossless_flac',
      name: 'CHD FLAC Audio Extractor',
      version: '1.1.0',
      publisher: const StorePublisher(
          id: 'sonichacker', name: 'SonicHacker', verified: false),
      description:
          'Extracts and decodes lossless CD audio tracks directly from CHD images.',
      tags: ['.chd', '.flac', '.wav'],
    ),
  ];

  static const StorePublisher _m5dev =
      StorePublisher(id: 'm5dev', name: 'M5 Dev', verified: true);

  static StorePlugin _defaultEntry({
    required String id,
    required String name,
    required String version,
    required StorePublisher publisher,
    required String description,
    required List<String> tags,
  }) {
    return StorePlugin(
      id: id,
      name: name,
      description: description,
      publisher: publisher,
      tags: tags,
      channels: {
        'stable': StoreChannel(channel: 'stable', version: version),
      },
    );
  }
}
