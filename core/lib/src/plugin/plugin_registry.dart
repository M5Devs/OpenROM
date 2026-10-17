// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'plugin_manifest.dart';

class RegisteredConversion {
  final String pluginId;
  final String from;
  final String to;
  final String commandTemplate;
  final String? executableRelPath;

  RegisteredConversion({
    required this.pluginId,
    required this.from,
    required this.to,
    required this.commandTemplate,
    this.executableRelPath,
  });
}

class PluginRegistry {
  static final PluginRegistry instance = PluginRegistry._internal();

  PluginRegistry._internal();

  final List<PluginManifest> _activePlugins = [];

  // Dynamic extension -> Format map
  final Map<String, String> _pluginSupportedInput = {};
  // Dynamic Format -> Platform display name map
  final Map<String, String> _pluginPlatformMap = {};
  // Dynamic Format -> Hex color badge map
  final Map<String, String> _pluginFormatColors = {};
  // Dynamic Format -> List of Target Formats
  final Map<String, List<String>> _pluginConversionMap = {};
  // Dynamic "FROM->TO" -> RegisteredConversion details
  final Map<String, RegisteredConversion> _pluginConversions = {};

  void clear() {
    _activePlugins.clear();
    _pluginSupportedInput.clear();
    _pluginPlatformMap.clear();
    _pluginFormatColors.clear();
    _pluginConversionMap.clear();
    _pluginConversions.clear();
  }

  void registerPlugin(PluginManifest manifest) {
    // Avoid duplicate registration
    _activePlugins.removeWhere((p) => p.id == manifest.id);
    _activePlugins.add(manifest);

    final platformBin = manifest.currentPlatformBinary;

    for (final ext in manifest.extensions) {
      final cleanExt = ext.ext.startsWith('.')
          ? ext.ext.toLowerCase()
          : '.${ext.ext.toLowerCase()}';
      final fmtUpper = ext.format.toUpperCase();

      _pluginSupportedInput[cleanExt] = fmtUpper;
      _pluginPlatformMap[fmtUpper] = ext.platform;
      _pluginFormatColors[fmtUpper] = ext.color;
    }

    for (final conv in manifest.conversions) {
      final fromUpper = conv.from.toUpperCase();
      final toUpper = conv.to.toUpperCase();
      final routeKey = '$fromUpper->$toUpper';

      final targets = _pluginConversionMap.putIfAbsent(fromUpper, () => []);
      if (!targets.contains(toUpper)) {
        targets.add(toUpper);
      }

      _pluginConversions[routeKey] = RegisteredConversion(
        pluginId: manifest.id,
        from: fromUpper,
        to: toUpper,
        commandTemplate: conv.command,
        executableRelPath: platformBin?.executable,
      );
    }
  }

  void unregisterPlugin(String pluginId) {
    _activePlugins.removeWhere((p) => p.id == pluginId);
    _rebuild();
  }

  void _rebuild() {
    final copy = List<PluginManifest>.from(_activePlugins);
    clear();
    for (final plugin in copy) {
      registerPlugin(plugin);
    }
  }

  Map<String, String> get supportedInput =>
      Map.unmodifiable(_pluginSupportedInput);
  Map<String, String> get platformMap => Map.unmodifiable(_pluginPlatformMap);
  Map<String, String> get formatColors => Map.unmodifiable(_pluginFormatColors);
  Map<String, List<String>> get conversionMap =>
      Map.unmodifiable(_pluginConversionMap);

  RegisteredConversion? getConversion(String from, String to) {
    final key = '${from.toUpperCase()}->${to.toUpperCase()}';
    return _pluginConversions[key];
  }

  List<PluginManifest> get activePlugins => List.unmodifiable(_activePlugins);
}
