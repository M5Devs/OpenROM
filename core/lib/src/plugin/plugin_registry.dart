// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'plugin_manifest.dart';

/// A plugin route that has been resolved against the current host.
///
/// Carries the owning manifest so the executor can read the structured
/// `execution` descriptor (environments, args, exit codes) rather than a raw
/// command string.
class RegisteredConversion {
  final String pluginId;
  final String from;
  final String to;

  /// Whether this plugin route is allowed to shadow a built-in core route.
  final bool override;

  /// The full manifest that registered the route.
  final PluginManifest manifest;

  /// Relative path to the host-platform executable, or empty when the plugin
  /// ships no build for this platform.
  final String executableRelPath;

  RegisteredConversion({
    required this.pluginId,
    required this.from,
    required this.to,
    required this.manifest,
    required this.executableRelPath,
    this.override = false,
  });

  String get key => '$from->$to';
}

/// In-memory registry of active plugins and the routes/formats they add.
///
/// Precedence is enforced by [resolveRoute]: a plugin route is only returned
/// when the plugin explicitly opted in with `"override": true`, or when the
/// core has no route for that pair. This prevents a plugin from silently
/// hijacking a built-in conversion (e.g. `ISO -> CHD`).
class PluginRegistry {
  static final PluginRegistry instance = PluginRegistry._internal();

  PluginRegistry._internal();

  final List<PluginManifest> _activePlugins = [];

  // Extension -> Format (e.g. '.cci' -> 'CCI')
  final Map<String, String> _pluginSupportedInput = {};
  // Format -> Platform display name
  final Map<String, String> _pluginPlatformMap = {};
  // Format -> Hex color badge
  final Map<String, String> _pluginFormatColors = {};
  // Format -> List of target formats
  final Map<String, List<String>> _pluginConversionMap = {};
  // "FROM->TO" -> RegisteredConversion
  final Map<String, RegisteredConversion> _pluginConversions = {};

  void clear() {
    _activePlugins.clear();
    _pluginSupportedInput.clear();
    _pluginPlatformMap.clear();
    _pluginFormatColors.clear();
    _pluginConversionMap.clear();
    _pluginConversions.clear();
  }

  /// Registers a validated manifest and all of its routes/formats.
  void registerPlugin(PluginManifest manifest) {
    _activePlugins.removeWhere((p) => p.id == manifest.id);
    _activePlugins.add(manifest);

    final platformBin = manifest.execution.currentEnvironment;

    for (final ext in manifest.extensions) {
      final cleanExt = ext.ext.startsWith('.')
          ? ext.ext.toLowerCase()
          : '.${ext.ext.toLowerCase()}';
      final fmtUpper = ext.format.toUpperCase();

      _pluginSupportedInput[cleanExt] = fmtUpper;
      _pluginPlatformMap[fmtUpper] = ext.platform;
      _pluginFormatColors[fmtUpper] = ext.color;
    }

    for (final route in manifest.routes) {
      final fromUpper = route.from.toUpperCase();
      final toUpper = route.to.toUpperCase();
      final routeKey = '$fromUpper->$toUpper';

      final targets = _pluginConversionMap.putIfAbsent(fromUpper, () => []);
      if (!targets.contains(toUpper)) {
        targets.add(toUpper);
      }

      _pluginConversions[routeKey] = RegisteredConversion(
        pluginId: manifest.id,
        from: fromUpper,
        to: toUpper,
        override: route.override,
        manifest: manifest,
        executableRelPath: platformBin?.executable ?? '',
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

  /// Raw lookup with no precedence applied. Prefer [resolveRoute].
  RegisteredConversion? getConversion(String from, String to) {
    final key = '${from.toUpperCase()}->${to.toUpperCase()}';
    return _pluginConversions[key];
  }

  /// Resolves a route honouring core precedence.
  ///
  /// [coreRoutes] is the set of `FROM->TO` keys the built-in engine handles.
  /// Returns the plugin conversion when:
  ///   * the plugin flagged the route `override: true`, or
  ///   * the core does not handle the route.
  /// Returns `null` otherwise (core wins), and when no plugin registered it.
  RegisteredConversion? resolveRoute(
    String from,
    String to,
    Set<String> coreRoutes,
  ) {
    final conv = getConversion(from, to);
    if (conv == null) return null;
    if (conv.override) return conv;
    if (coreRoutes.contains(conv.key)) return null;
    return conv;
  }

  /// True when a plugin has claimed `from`->`to` with an explicit override.
  bool hasOverride(String from, String to) =>
      getConversion(from, to)?.override ?? false;

  List<PluginManifest> get activePlugins => List.unmodifiable(_activePlugins);

  /// The plugin that owns a given id, if installed.
  PluginManifest? pluginById(String pluginId) {
    for (final plugin in _activePlugins) {
      if (plugin.id == pluginId) return plugin;
    }
    return null;
  }
}
