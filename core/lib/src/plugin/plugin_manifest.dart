// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:ffi';
import 'dart:io';

class PluginBinary {
  final String executable;
  final String sha256;

  PluginBinary({
    required this.executable,
    required this.sha256,
  });

  factory PluginBinary.fromJson(Map<String, dynamic> json) {
    return PluginBinary(
      executable: json['executable'] as String? ?? '',
      sha256: json['sha256'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'executable': executable,
      'sha256': sha256,
    };
  }
}

class PluginExtension {
  final String ext;
  final String format;
  final String platform;
  final String color;

  PluginExtension({
    required this.ext,
    required this.format,
    required this.platform,
    required this.color,
  });

  factory PluginExtension.fromJson(Map<String, dynamic> json) {
    return PluginExtension(
      ext: json['ext'] as String? ?? '',
      format: json['format'] as String? ?? '',
      platform: json['platform'] as String? ?? '',
      color: json['color'] as String? ?? '#7a8a9a',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ext': ext,
      'format': format,
      'platform': platform,
      'color': color,
    };
  }
}

class PluginConversion {
  final String from;
  final String to;
  final String command;

  PluginConversion({
    required this.from,
    required this.to,
    required this.command,
  });

  factory PluginConversion.fromJson(Map<String, dynamic> json) {
    return PluginConversion(
      from: json['from'] as String? ?? '',
      to: json['to'] as String? ?? '',
      command: json['command'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'to': to,
      'command': command,
    };
  }
}

class PluginManifest {
  final String id;
  final String name;
  final String version;
  final String author;
  final String description;
  final String minCoreVersion;
  final Map<String, PluginBinary> binaries;
  final List<PluginExtension> extensions;
  final List<PluginConversion> conversions;

  PluginManifest({
    required this.id,
    required this.name,
    required this.version,
    required this.author,
    required this.description,
    required this.minCoreVersion,
    required this.binaries,
    required this.extensions,
    required this.conversions,
  });

  factory PluginManifest.fromJson(Map<String, dynamic> json) {
    final rawBinaries = json['binaries'] as Map<String, dynamic>? ?? {};
    final binaries = rawBinaries.map(
      (k, v) => MapEntry(
        k,
        PluginBinary.fromJson(v as Map<String, dynamic>? ?? {}),
      ),
    );

    final rawExts = json['extensions'] as List<dynamic>? ?? [];
    final extensions = rawExts
        .map((e) => PluginExtension.fromJson(e as Map<String, dynamic>? ?? {}))
        .toList();

    final rawConvs = json['conversions'] as List<dynamic>? ?? [];
    final conversions = rawConvs
        .map((c) => PluginConversion.fromJson(c as Map<String, dynamic>? ?? {}))
        .toList();

    return PluginManifest(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      version: json['version'] as String? ?? '',
      author: json['author'] as String? ?? '',
      description: json['description'] as String? ?? '',
      minCoreVersion: json['minCoreVersion'] as String? ?? '',
      binaries: binaries,
      extensions: extensions,
      conversions: conversions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'author': author,
      'description': description,
      'minCoreVersion': minCoreVersion,
      'binaries': binaries.map((k, v) => MapEntry(k, v.toJson())),
      'extensions': extensions.map((e) => e.toJson()).toList(),
      'conversions': conversions.map((c) => c.toJson()).toList(),
    };
  }

  /// Validates that the manifest has required fields and valid schema.
  List<String> validate() {
    final errors = <String>[];
    if (id.trim().isEmpty) {
      errors.add('Plugin "id" is required.');
    } else if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(id)) {
      errors.add(
          'Plugin "id" must contain only alphanumeric characters, underscores, or hyphens.');
    }

    if (name.trim().isEmpty) {
      errors.add('Plugin "name" is required.');
    }
    if (version.trim().isEmpty) {
      errors.add('Plugin "version" is required.');
    }
    if (minCoreVersion.trim().isEmpty) {
      errors.add('Plugin "minCoreVersion" is required.');
    }

    for (final ext in extensions) {
      if (ext.ext.trim().isEmpty) {
        errors.add('Extension "ext" cannot be empty.');
      }
      if (ext.format.trim().isEmpty) {
        errors.add('Extension "format" cannot be empty.');
      }
    }

    for (final conv in conversions) {
      if (conv.from.trim().isEmpty || conv.to.trim().isEmpty) {
        errors.add('Conversion "from" and "to" cannot be empty.');
      }
      if (conv.command.trim().isEmpty) {
        errors.add('Conversion "command" cannot be empty.');
      }
    }

    return errors;
  }

  /// Helper to get the binary details for the current host platform.
  PluginBinary? get currentPlatformBinary {
    final platformKey = getCurrentPlatformKey();
    return binaries[platformKey];
  }
}

/// Helper function to resolve host platform key string.
String getCurrentPlatformKey() {
  if (Platform.isWindows) {
    return 'windows_x64';
  } else if (Platform.isLinux) {
    try {
      final abiStr = Abi.current().toString().toLowerCase();
      if (abiStr.contains('arm64') || abiStr.contains('aarch64')) {
        return 'linux_arm64';
      }
    } catch (_) {}
    return 'linux_x64';
  } else if (Platform.isMacOS) {
    try {
      final abiStr = Abi.current().toString().toLowerCase();
      if (abiStr.contains('arm64') || abiStr.contains('aarch64')) {
        return 'macos_arm64';
      }
    } catch (_) {}
    return 'macos_x64';
  }
  return '';
}
