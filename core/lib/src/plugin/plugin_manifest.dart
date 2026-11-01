// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:ffi';
import 'dart:io';

import 'plugin_version.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// Plugin manifest model (`plugin.json` inside a `.orplug` archive).
///
/// The schema is intentionally declarative: a plugin describes *what* it can
/// do (routes) and *how to run* its binary (structured `execution`), never a
/// raw shell string. This removes the command-injection surface entirely —
/// arguments are passed to `Process.start` as a pre-split array, never parsed
/// or evaluated by a shell.
///
/// ```json
/// {
///   "schemaVersion": 2,
///   "id": "xbox360-tools",
///   "name": "Xbox 360 Tools",
///   "version": "1.2.0",
///   "minCoreVersion": "3.9.0",
///   "description": "Xbox 360 CCI/ZAR <-> ISO",
///   "publisher": { "id": "m5dev", "name": "M5 Dev", "verified": true },
///   "routes": [
///     { "from": "CCI", "to": "ISO", "override": false }
///   ],
///   "execution": {
///     "kind": "process",
///     "timeoutSeconds": 0,
///     "successExitCodes": [0],
///     "environments": {
///       "linux_x64":   { "executable": "bin/xgdtool",     "sha256": "…" },
///       "windows_x64": { "executable": "bin/XGDTool.exe", "sha256": "…" }
///     },
///     "args": [
///       { "kind": "executable" },
///       { "kind": "literal", "value": "--xiso" },
///       { "kind": "input" },
///       { "kind": "literal", "value": "--out" },
///       { "kind": "outputDir" }
///     ]
///   },
///   "extensions": [
///     { "ext": ".cci", "format": "CCI", "platform": "Xbox 360", "color": "#4caf50" }
///   ]
/// }
/// ```
/// ─────────────────────────────────────────────────────────────────────────

/// Current manifest schema version understood by this build.
const int kPluginSchemaVersion = 2;

/// Strict, case-sensitive plugin identifier: lowercase alphanumerics, `_`, `-`.
final RegExp kPluginIdPattern = RegExp(r'^[a-z0-9_-]+$');

/// Tokens a plugin argument may reference. Each maps to a value the executor
/// resolves at run time; none of them is ever passed through a shell.
enum PluginArgKind {
  /// Absolute path to the plugin's resolved platform executable.
  executable,

  /// A fixed literal string from the manifest (`value`).
  literal,

  /// Absolute path of the input ROM.
  input,

  /// Absolute path of the output file (derived from the target format).
  output,

  /// Absolute path of the output *directory*.
  outputDir,

  /// Path to the input ROM's paired `.cue` (or a generated one), if any.
  cue,

  /// Basename of the input file.
  inputName,

  /// Basename of the output file.
  outputName;

  static PluginArgKind? fromName(String name) {
    for (final kind in PluginArgKind.values) {
      if (kind.name == name) return kind;
    }
    return null;
  }
}

/// How a plugin executable is invoked.
enum PluginExecutionKind {
  /// Run a native binary / script via `Process.start`.
  process,

  /// Reserved for future in-process execution. Not supported yet.
  library;

  static PluginExecutionKind? fromName(String name) {
    for (final kind in PluginExecutionKind.values) {
      if (kind.name == name) return kind;
    }
    return null;
  }
}

/// One structured argument passed to the plugin process.
class PluginArg {
  final PluginArgKind kind;

  /// Only meaningful for [PluginArgKind.literal].
  final String value;

  const PluginArg({required this.kind, this.value = ''});

  factory PluginArg.fromJson(Map<String, dynamic> json) {
    final kind = PluginArgKind.fromName(json['kind'] as String? ?? '');
    return PluginArg(
      kind: kind ?? PluginArgKind.literal,
      value: json['value'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        if (kind == PluginArgKind.literal) 'value': value,
      };

  /// Resolves this argument to a concrete argv element.
  ///
  /// [values] supplies the runtime paths keyed by [PluginArgKind]. Returns
  /// `null` when the argument cannot be resolved (e.g. a required path that
  /// does not exist), which the executor treats as a hard failure rather than
  /// passing a dangling value to the tool.
  String? resolve(Map<PluginArgKind, String> values) {
    if (kind == PluginArgKind.literal) return value;
    return values[kind];
  }
}

/// Binary descriptor for a single OS/arch environment.
class PluginEnvironment {
  final String executable;
  final String sha256;

  const PluginEnvironment({required this.executable, required this.sha256});

  factory PluginEnvironment.fromJson(Map<String, dynamic> json) =>
      PluginEnvironment(
        executable: json['executable'] as String? ?? '',
        sha256: json['sha256'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'executable': executable,
        'sha256': sha256,
      };
}

/// Execution descriptor: the structured replacement for command templates.
class PluginExecution {
  final PluginExecutionKind kind;

  /// Per-environment binaries, keyed by platform key (see [currentPlatformKey]).
  final Map<String, PluginEnvironment> environments;

  /// Ordered argument vector, resolved at run time.
  final List<PluginArg> args;

  /// Exit codes considered successful. Defaults to `[0]`.
  final List<int> successExitCodes;

  /// Optional hard timeout. `Duration.zero` disables the timeout.
  final Duration timeout;

  /// Environment variables injected into the child process. Plain data only.
  final Map<String, String> environment;

  const PluginExecution({
    this.kind = PluginExecutionKind.process,
    this.environments = const {},
    this.args = const [],
    this.successExitCodes = const [0],
    this.timeout = Duration.zero,
    this.environment = const {},
  });

  factory PluginExecution.fromJson(Map<String, dynamic> json) {
    final rawEnvs = json['environments'] as Map<String, dynamic>? ?? {};
    final environments = rawEnvs.map(
      (k, v) => MapEntry(
        k,
        PluginEnvironment.fromJson(v as Map<String, dynamic>? ?? {}),
      ),
    );

    final rawArgs = json['args'] as List<dynamic>? ?? [];
    final args = rawArgs
        .whereType<Map<String, dynamic>>()
        .map(PluginArg.fromJson)
        .toList();

    final rawExit = json['successExitCodes'] as List<dynamic>?;
    final successExitCodes = (rawExit == null || rawExit.isEmpty)
        ? const [0]
        : rawExit.map((e) => (e as num).toInt()).toList();

    final rawEnv = json['environment'] as Map<String, dynamic>? ?? {};

    return PluginExecution(
      kind:
          PluginExecutionKind.fromName(json['kind'] as String? ?? 'process') ??
              PluginExecutionKind.process,
      environments: environments,
      args: args,
      successExitCodes: successExitCodes,
      timeout:
          Duration(seconds: (json['timeoutSeconds'] as num?)?.toInt() ?? 0),
      environment: rawEnv.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'environments': environments.map((k, v) => MapEntry(k, v.toJson())),
        'args': args.map((a) => a.toJson()).toList(),
        'successExitCodes': successExitCodes,
        if (timeout.inSeconds > 0) 'timeoutSeconds': timeout.inSeconds,
        if (environment.isNotEmpty) 'environment': environment,
      };

  /// The binary descriptor for the current host, or `null` if the plugin does
  /// not ship a build for this platform.
  PluginEnvironment? get currentEnvironment =>
      environments[currentPlatformKey()];

  bool get supportsCurrentPlatform => currentEnvironment != null;
}

/// A conversion route the plugin advertises (e.g. `CCI -> ISO`).
class PluginRoute {
  final String from;
  final String to;

  /// When `true`, the plugin is allowed to take over a route that a built-in
  /// converter also handles. Defaults to `false` so plugins can never shadow
  /// core flows by accident or malice.
  final bool override;

  const PluginRoute({
    required this.from,
    required this.to,
    this.override = false,
  });

  factory PluginRoute.fromJson(Map<String, dynamic> json) => PluginRoute(
        from: (json['from'] as String? ?? '').toUpperCase(),
        to: (json['to'] as String? ?? '').toUpperCase(),
        override: json['override'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'from': from,
        'to': to,
        if (override) 'override': true,
      };

  String get key => '$from->$to';
}

/// Extension → format registration (drives detection + UI badges).
class PluginExtension {
  final String ext;
  final String format;
  final String platform;
  final String color;

  const PluginExtension({
    required this.ext,
    required this.format,
    required this.platform,
    required this.color,
  });

  factory PluginExtension.fromJson(Map<String, dynamic> json) =>
      PluginExtension(
        ext: json['ext'] as String? ?? '',
        format: json['format'] as String? ?? '',
        platform: json['platform'] as String? ?? '',
        color: json['color'] as String? ?? '#7a8a9a',
      );

  Map<String, dynamic> toJson() => {
        'ext': ext,
        'format': format,
        'platform': platform,
        'color': color,
      };
}

/// Publisher / trust metadata. Drives the "verified" badge in the store UI.
class PluginPublisher {
  final String id;
  final String name;
  final bool verified;

  const PluginPublisher({
    required this.id,
    required this.name,
    this.verified = false,
  });

  /// Convenience for legacy manifests that only carried a free-form author.
  factory PluginPublisher.legacy(String author) => PluginPublisher(
        id: _slugify(author),
        name: author.isEmpty ? 'Unknown' : author,
        verified: false,
      );

  factory PluginPublisher.fromJson(Map<String, dynamic> json) =>
      PluginPublisher(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        verified: json['verified'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'verified': verified,
      };

  static String _slugify(String value) {
    final lowered =
        value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_-]+'), '-');
    return lowered.replaceAll(RegExp(r'^-+|-+$'), '');
  }
}

/// The complete, validated plugin manifest.
class PluginManifest {
  final int schemaVersion;
  final String id;
  final String name;
  final SemVer version;
  final SemVer? minCoreVersion;
  final String description;
  final PluginPublisher publisher;
  final List<PluginRoute> routes;
  final PluginExecution execution;
  final List<PluginExtension> extensions;

  const PluginManifest({
    this.schemaVersion = kPluginSchemaVersion,
    required this.id,
    required this.name,
    required this.version,
    required this.minCoreVersion,
    this.description = '',
    required this.publisher,
    this.routes = const [],
    this.execution = const PluginExecution(),
    this.extensions = const [],
  });

  /// Builds a manifest from JSON, accepting both the current schema and the
  /// legacy v1 layout (`binaries` + `conversions` + `command` template +
  /// `author`). Legacy fields are normalised into the new model so existing
  /// `.orplug` archives keep loading.
  factory PluginManifest.fromJson(Map<String, dynamic> json) {
    final rawPublisher = json['publisher'] as Map<String, dynamic>?;
    final publisher = rawPublisher != null
        ? PluginPublisher.fromJson(rawPublisher)
        : PluginPublisher.legacy(json['author'] as String? ?? '');

    final rawExtensions = json['extensions'] as List<dynamic>? ?? [];
    final extensions = rawExtensions
        .whereType<Map<String, dynamic>>()
        .map(PluginExtension.fromJson)
        .toList();

    final rawRoutes = json['routes'] as List<dynamic>?;
    final rawExecution = json['execution'] as Map<String, dynamic>?;

    if (rawRoutes != null || rawExecution != null) {
      return PluginManifest(
        schemaVersion:
            (json['schemaVersion'] as num?)?.toInt() ?? kPluginSchemaVersion,
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        version: SemVer.tryParse(json['version'] as String? ?? '') ??
            const SemVer(0, 0, 0),
        minCoreVersion: SemVer.tryParseLoose(json['minCoreVersion'] as String?),
        description: json['description'] as String? ?? '',
        publisher: publisher,
        routes: (rawRoutes ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(PluginRoute.fromJson)
            .toList(),
        execution: rawExecution != null
            ? PluginExecution.fromJson(rawExecution)
            : const PluginExecution(),
        extensions: extensions,
      );
    }

    return PluginManifest._fromLegacy(json, publisher, extensions);
  }

  factory PluginManifest._fromLegacy(
    Map<String, dynamic> json,
    PluginPublisher publisher,
    List<PluginExtension> extensions,
  ) {
    final rawBinaries = json['binaries'] as Map<String, dynamic>? ?? {};
    final environments = rawBinaries.map(
      (k, v) => MapEntry(
        k,
        PluginEnvironment.fromJson(v as Map<String, dynamic>? ?? {}),
      ),
    );

    final rawConversions = json['conversions'] as List<dynamic>? ?? [];
    final routes = <PluginRoute>[];
    final legacyArgs = <PluginArg>[];
    final seenKinds = <PluginArgKind>{};

    for (final raw in rawConversions.whereType<Map<String, dynamic>>()) {
      routes.add(PluginRoute(
        from: (raw['from'] as String? ?? '').toUpperCase(),
        to: (raw['to'] as String? ?? '').toUpperCase(),
      ));
    }

    final template = rawConversions
        .whereType<Map<String, dynamic>>()
        .map((c) => c['command'] as String? ?? '')
        .firstWhere((c) => c.isNotEmpty, orElse: () => '');

    if (template.isNotEmpty) {
      for (final token in _tokenizeLegacyTemplate(template)) {
        final arg = _legacyTokenToArg(token);
        if (arg.kind != PluginArgKind.literal && !seenKinds.add(arg.kind)) {
          continue;
        }
        legacyArgs.add(arg);
      }
    }

    return PluginManifest(
      schemaVersion: 1,
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      version: SemVer.tryParse(json['version'] as String? ?? '') ??
          const SemVer(0, 0, 0),
      minCoreVersion: SemVer.tryParseLoose(json['minCoreVersion'] as String?),
      description: json['description'] as String? ?? '',
      publisher: publisher,
      routes: routes,
      execution: PluginExecution(
        environments: environments,
        args: legacyArgs,
      ),
      extensions: extensions,
    );
  }

  /// Tokenises a legacy command template on whitespace, honouring single and
  /// double quotes. Used only for *migration*, never for execution.
  static List<String> _tokenizeLegacyTemplate(String template) {
    final tokens = <String>[];
    final buffer = StringBuffer();
    var inDouble = false;
    var inSingle = false;
    for (var i = 0; i < template.length; i++) {
      final ch = template[i];
      if (ch == '"' && !inSingle) {
        inDouble = !inDouble;
      } else if (ch == "'" && !inDouble) {
        inSingle = !inSingle;
      } else if (ch == ' ' && !inDouble && !inSingle) {
        if (buffer.isNotEmpty) {
          tokens.add(buffer.toString());
          buffer.clear();
        }
      } else {
        buffer.write(ch);
      }
    }
    if (buffer.isNotEmpty) tokens.add(buffer.toString());
    return tokens;
  }

  static PluginArg _legacyTokenToArg(String token) {
    switch (token) {
      case '{bin}':
        return const PluginArg(kind: PluginArgKind.executable);
      case '{in}':
        return const PluginArg(kind: PluginArgKind.input);
      case '{out}':
        return const PluginArg(kind: PluginArgKind.output);
      case '{outdir}':
        return const PluginArg(kind: PluginArgKind.outputDir);
      case '{cue}':
      case '{out_cue}':
        return const PluginArg(kind: PluginArgKind.cue);
      default:
        return PluginArg(kind: PluginArgKind.literal, value: token);
    }
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'id': id,
        'name': name,
        'version': version.toString(),
        'minCoreVersion': minCoreVersion?.toString() ?? '',
        'description': description,
        'publisher': publisher.toJson(),
        'routes': routes.map((r) => r.toJson()).toList(),
        'execution': execution.toJson(),
        'extensions': extensions.map((e) => e.toJson()).toList(),
      };

  /// Publisher display name; kept for UI code that predates the publisher model.
  String get author => publisher.name;

  /// Legacy alias for [execution.environments].
  Map<String, PluginEnvironment> get binaries => execution.environments;

  /// Legacy alias for [routes].
  List<PluginRoute> get conversions => routes;

  PluginEnvironment? get currentPlatformBinary => execution.currentEnvironment;

  /// Full structural validation. Returns an empty list when the manifest is
  /// valid; otherwise one human-readable message per problem.
  List<String> validate() {
    final errors = <String>[];

    if (schemaVersion > kPluginSchemaVersion) {
      errors.add(
          'Plugin "schemaVersion" $schemaVersion is newer than this build supports ($kPluginSchemaVersion).');
    }

    if (id.trim().isEmpty) {
      errors.add('Plugin "id" is required.');
    } else if (!kPluginIdPattern.hasMatch(id)) {
      errors.add(
          'Plugin "id" must match ^[a-z0-9_-]+\$ (lowercase letters, digits, "_" or "-").');
    }

    if (name.trim().isEmpty) {
      errors.add('Plugin "name" is required.');
    }

    if (version.major == 0 &&
        version.minor == 0 &&
        version.patch == 0 &&
        version.toString() != '0.0.0') {
      errors.add('Plugin "version" must be a valid SemVer (e.g. "1.2.0").');
    }

    if (publisher.id.trim().isEmpty) {
      errors.add('Plugin "publisher.id" is required.');
    }

    if (execution.kind == PluginExecutionKind.process) {
      if (execution.environments.isEmpty) {
        errors.add(
            'Plugin "execution.environments" must declare at least one platform binary.');
      }
      if (execution.args.isEmpty) {
        errors
            .add('Plugin "execution.args" must contain at least one argument.');
      }
      if (execution.successExitCodes.isEmpty) {
        errors.add('Plugin "execution.successExitCodes" must not be empty.');
      }
      execution.environments.forEach((key, env) {
        if (env.executable.trim().isEmpty) {
          errors.add('Plugin binary for "$key" is missing an "executable".');
        } else if (_isUnsafeRelativePath(env.executable)) {
          errors.add(
              'Plugin binary for "$key" must be a relative path inside the plugin (got "${env.executable}").');
        }
        if (env.sha256.trim().isEmpty) {
          errors
              .add('Plugin binary for "$key" is missing a "sha256" checksum.');
        } else if (!_isHex64(env.sha256)) {
          errors.add(
              'Plugin binary for "$key" has a malformed "sha256" (expected 64 hex chars).');
        }
      });
      for (var i = 0; i < execution.args.length; i++) {
        final arg = execution.args[i];
        if (arg.kind == PluginArgKind.literal && arg.value.isEmpty) {
          errors.add('Plugin "execution.args" contains an empty literal.');
        }
        if (arg.kind == PluginArgKind.executable && i != 0) {
          errors.add(
              'Plugin "execution.args" may only use the "executable" token as its first argument.');
        }
      }
    }

    for (final route in routes) {
      if (route.from.trim().isEmpty || route.to.trim().isEmpty) {
        errors.add('Plugin route "from"/"to" must not be empty.');
      }
    }

    for (final ext in extensions) {
      if (ext.ext.trim().isEmpty) {
        errors.add('Extension "ext" cannot be empty.');
      }
      if (ext.format.trim().isEmpty) {
        errors.add('Extension "format" cannot be empty.');
      }
    }

    return errors;
  }

  /// True when the manifest declares it can run on the current host.
  bool get supportsHostPlatform => execution.supportsCurrentPlatform;

  static bool _isUnsafeRelativePath(String path) {
    if (path.trim().isEmpty) return true;
    if (path.startsWith('/') || path.startsWith('\\')) return true;
    if (RegExp(r'^[a-zA-Z]:').hasMatch(path)) return true; // Windows drive
    final segments = path.split(RegExp(r'[\\/]+'));
    return segments.contains('..');
  }

  static bool _isHex64(String value) =>
      RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(value.trim());
}

/// Resolves the host platform key used to select a plugin binary, e.g.
/// `linux_x64`, `linux_arm64`, `macos_arm64`, `macos_x64`, `windows_x64`.
String currentPlatformKey() {
  if (Platform.isWindows) {
    return _isArm64() ? 'windows_arm64' : 'windows_x64';
  } else if (Platform.isLinux) {
    return _isArm64() ? 'linux_arm64' : 'linux_x64';
  } else if (Platform.isMacOS) {
    return _isArm64() ? 'macos_arm64' : 'macos_x64';
  } else if (Platform.isAndroid) {
    return _isArm64() ? 'android_arm64' : 'android_x64';
  }
  return '';
}

bool _isArm64() {
  try {
    final abi = Abi.current().toString().toLowerCase();
    return abi.contains('arm64') || abi.contains('aarch64');
  } catch (_) {
    return false;
  }
}

/// Backwards-compatible alias for the pre-refactor helper name.
String getCurrentPlatformKey() => currentPlatformKey();
