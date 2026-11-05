// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:openrom_core/openrom_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/plugin_service.dart';

class PluginController extends ChangeNotifier {
  final PluginService _service;

  List<PluginManifest> _installedPlugins = [];
  List<StorePlugin> _storeCatalog = [];
  List<StoreListing> _storeListings = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _statusMessage;

  /// Whether [storeListings] came from the live API (`true`) or the offline
  /// cache (`false`). Drives the "offline" badge in the storefront.
  bool _storeIsLive = false;

  /// `true` once a live fetch has been attempted in this session.
  bool _storeFetchAttempted = false;

  String _storeQuery = '';
  String? _storeCategory;

  PluginController({PluginService? service})
      : _service = service ?? PluginService();

  List<PluginManifest> get installedPlugins =>
      List.unmodifiable(_installedPlugins);
  List<StorePlugin> get storeCatalog => List.unmodifiable(_storeCatalog);
  List<StoreListing> get storeListings => List.unmodifiable(_storeListings);
  bool get storeIsLive => _storeIsLive;
  bool get storeFetchAttempted => _storeFetchAttempted;
  String get storeQuery => _storeQuery;
  String? get storeCategory => _storeCategory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get statusMessage => _statusMessage;

  /// The listings matching the current [storeQuery] and [storeCategory].
  List<StoreListing> get filteredStoreListings {
    final q = _storeQuery.trim().toLowerCase();
    return _storeListings.where((l) {
      if (_storeCategory != null && l.category != _storeCategory) return false;
      if (q.isEmpty) return true;
      return l.name.toLowerCase().contains(q) ||
          l.id.toLowerCase().contains(q) ||
          l.description.toLowerCase().contains(q) ||
          l.publisherName.toLowerCase().contains(q) ||
          l.routes.any((r) => r.toLowerCase().contains(q));
    }).toList();
  }

  /// Categories present in the current catalogue, in [kStoreCategories] order,
  /// followed by any unknown categories the store introduces.
  List<String> get storeCategories {
    final present = _storeListings.map((l) => l.category).toSet()
      ..removeWhere((c) => c.isEmpty);
    final known = kStoreCategories.where(present.contains).toList();
    final extra = present.where((c) => !kStoreCategories.contains(c)).toList()
      ..sort();
    return [...known, ...extra];
  }

  void setStoreQuery(String query) {
    if (_storeQuery == query) return;
    _storeQuery = query;
    notifyListeners();
  }

  void setStoreCategory(String? category) {
    if (_storeCategory == category) return;
    _storeCategory = category;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Refreshes the list of locally installed plugins.
  Future<void> loadInstalledPlugins() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _installedPlugins = await _service.loadInstalledPlugins();
    } catch (e) {
      _errorMessage = 'Failed to load installed plugins: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches available store catalog items.
  Future<void> fetchStoreCatalog({String? endpointUrl}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _storeCatalog = await _service.fetchStoreCatalog(
        endpointUrl: endpointUrl,
      );
    } catch (e) {
      _errorMessage = 'Failed to fetch plugin store catalog: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches the live storefront catalogue, falling back to the last cached
  /// copy (persisted in `SharedPreferences`) when the API is unreachable.
  ///
  /// Never surfaces a network error as an error banner: an offline store is a
  /// normal state, not a failure. Instead [storeIsLive] goes false and the UI
  /// shows the cached catalogue with an "offline" badge.
  Future<void> fetchLiveStore({String? endpointUrl, bool force = false}) async {
    if (_storeFetchAttempted && !force && _storeListings.isNotEmpty) return;

    _storeFetchAttempted = true;
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _service.fetchLiveStore(endpointUrl: endpointUrl);
      if (result != null) {
        _storeListings = result.listings;
        _storeIsLive = true;
        await _cacheStorePayload(result.raw);
      } else {
        _storeListings = await _readCachedStore();
        _storeIsLive = false;
      }
    } catch (e) {
      _storeListings = await _readCachedStore();
      _storeIsLive = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Installs a live storefront listing.
  Future<bool> installListing(StoreListing listing) async {
    _isLoading = true;
    _statusMessage = 'Downloading ${listing.name}...';
    _errorMessage = null;
    notifyListeners();

    try {
      final outcome = await _service.installFromListing(listing);
      if (outcome.success) {
        _statusMessage = 'Plugin installed successfully!';
        await loadInstalledPlugins();
        return true;
      }
      _errorMessage = outcome.error ?? 'Failed to install plugin.';
      return false;
    } catch (e) {
      _errorMessage = 'Error during plugin installation: $e';
      return false;
    } finally {
      _isLoading = false;
      _statusMessage = null;
      notifyListeners();
    }
  }

  Future<void> _cacheStorePayload(String raw) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storeCacheKey, raw);
    } catch (_) {}
  }

  Future<List<StoreListing>> _readCachedStore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storeCacheKey);
      if (raw == null || raw.isEmpty) return const [];
      return StoreListing.listFromJson(jsonDecode(raw));
    } catch (_) {
      return const [];
    }
  }

  static const String _storeCacheKey = 'openrom_store_cache_v1';

  /// Installs a `.orplug` package from a file path.
  Future<bool> installPluginFromPath(String orplugPath) async {
    _isLoading = true;
    _statusMessage = 'Installing plugin...';
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _service.installPlugin(orplugPath);
      if (success) {
        _statusMessage = 'Plugin installed successfully!';
        await loadInstalledPlugins();
        return true;
      } else {
        _errorMessage =
            'Failed to install plugin. Check manifest and SHA256 integrity.';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error during plugin installation: $e';
      return false;
    } finally {
      _isLoading = false;
      _statusMessage = null;
      notifyListeners();
    }
  }

  /// Downloads and installs a plugin from the store registry, verifying the
  /// artifact against its published SHA-256 before installation.
  Future<bool> installFromStore(StorePlugin storePlugin) async {
    _isLoading = true;
    _statusMessage = 'Downloading ${storePlugin.name}...';
    _errorMessage = null;
    notifyListeners();

    try {
      final outcome = await _service.installFromStore(storePlugin);
      if (outcome.success) {
        _statusMessage = 'Plugin installed successfully!';
        await loadInstalledPlugins();
        return true;
      }
      _errorMessage = outcome.error ?? 'Failed to install plugin.';
      return false;
    } catch (e) {
      _errorMessage = 'Error during plugin installation: $e';
      return false;
    } finally {
      _isLoading = false;
      _statusMessage = null;
      notifyListeners();
    }
  }

  /// Opens file picker for `.orplug` files and installs the selected file.
  Future<bool> pickAndInstallPlugin() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['orplug', 'zip'],
      );

      if (result != null && result.files.single.path != null) {
        return await installPluginFromPath(result.files.single.path!);
      }
    } catch (e) {
      _errorMessage = 'Failed to pick plugin file: $e';
      notifyListeners();
    }
    return false;
  }

  /// Uninstalls an installed plugin by ID.
  Future<bool> uninstallPlugin(String pluginId) async {
    _isLoading = true;
    _statusMessage = 'Uninstalling plugin...';
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _service.uninstallPlugin(pluginId);
      if (success) {
        _statusMessage = 'Plugin uninstalled successfully.';
        await loadInstalledPlugins();
        return true;
      } else {
        _errorMessage = 'Failed to uninstall plugin "$pluginId".';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error during plugin uninstallation: $e';
      return false;
    } finally {
      _isLoading = false;
      _statusMessage = null;
      notifyListeners();
    }
  }

  /// Helper to check if a store plugin ID is already installed.
  bool isPluginInstalled(String pluginId) {
    return _installedPlugins.any((p) => p.id == pluginId);
  }
}
