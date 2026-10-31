// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:openrom_core/openrom_core.dart';

import '../services/plugin_service.dart';

class PluginController extends ChangeNotifier {
  final PluginService _service;

  List<PluginManifest> _installedPlugins = [];
  List<StorePlugin> _storeCatalog = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _statusMessage;

  PluginController({PluginService? service})
      : _service = service ?? PluginService();

  List<PluginManifest> get installedPlugins =>
      List.unmodifiable(_installedPlugins);
  List<StorePlugin> get storeCatalog => List.unmodifiable(_storeCatalog);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get statusMessage => _statusMessage;

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
