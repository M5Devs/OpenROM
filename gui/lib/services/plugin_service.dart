// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:openrom_core/openrom_core.dart';

import '../models/store_plugin.dart';

class PluginService {
  final PluginManager _pluginManager;

  PluginService({PluginManager? pluginManager})
      : _pluginManager = pluginManager ?? PluginManager.instance;

  /// Loads all installed plugins and returns active manifests.
  Future<List<PluginManifest>> loadInstalledPlugins() async {
    await _pluginManager.loadInstalledPlugins();
    return _pluginManager.installedPlugins;
  }

  /// Installs a plugin from a local `.orplug` ZIP archive path.
  Future<bool> installPlugin(String orplugPath) async {
    return await _pluginManager.installPlugin(orplugPath);
  }

  /// Uninstalls a plugin by its ID.
  Future<bool> uninstallPlugin(String pluginId) async {
    return await _pluginManager.uninstallPlugin(pluginId);
  }

  /// Fetches available plugins for the Plugin Store catalog.
  /// Attempts to fetch from optional remote endpoint, falling back to default store plugins.
  Future<List<StorePlugin>> fetchStoreCatalog({String? endpointUrl}) async {
    if (endpointUrl != null && endpointUrl.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(endpointUrl));
        if (response.statusCode == 200) {
          final List<dynamic> jsonList = jsonDecode(response.body);
          return jsonList
              .map((e) => StorePlugin.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {}
    }

    return _defaultStoreCatalog;
  }

  static const List<StorePlugin> _defaultStoreCatalog = [
    StorePlugin(
      id: 'xgdtool_360',
      name: 'Xbox 360 XGDTool Engine',
      version: '1.2.0',
      author: 'M5 Dev',
      description:
          'Adds full conversion support for Xbox 360 compressed disc formats (.zar, .cci) to standard ISO.',
      isVerified: true,
      tags: ['.zar', '.cci', '.iso'],
    ),
    StorePlugin(
      id: 'saturn_ssp',
      name: 'Sega Saturn SSP Patcher',
      version: '1.0.4',
      author: 'M5 Dev',
      description:
          'Enables native creation and application of Sega Saturn SSP patch files with Mode-1 EDC/ECC recalculation.',
      isVerified: true,
      tags: ['.ssp', '.iso'],
    ),
    StorePlugin(
      id: 'nkit_gc_wii',
      name: 'NKit GameCube & Wii Suite',
      version: '2.1.0',
      author: 'M5 Dev',
      description:
          'Supports raw disc image restoration and conversion for NKit (.nkit.iso, .wud, .wux, .wua) formats.',
      isVerified: true,
      tags: ['.nkit.iso', '.wud', '.wux', '.wua'],
    ),
    StorePlugin(
      id: 'ps2_gz_compressor',
      name: 'PS2 GZ ISO Tool',
      version: '0.8.2',
      author: 'RetroCommunity',
      description:
          'Fast block gzip compression and decompression plugin for PlayStation 2 DVD ISOs.',
      isVerified: false,
      tags: ['.gz', '.iso'],
    ),
    StorePlugin(
      id: 'chd_lossless_flac',
      name: 'CHD FLAC Audio Extractor',
      version: '1.1.0',
      author: 'SonicHacker',
      description:
          'Extracts and decodes lossless CD audio tracks directly from CHD images.',
      isVerified: false,
      tags: ['.chd', '.flac', '.wav'],
    ),
  ];
}
