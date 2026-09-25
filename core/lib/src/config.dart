// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

const String appName = 'OpenROM';

String getDirectoryConfig() {
  String path;
  if (Platform.isWindows) {
    final base = Platform.environment['APPDATA'] ?? Platform.environment['USERPROFILE'] ?? '';
    path = p.join(base, appName);
  } else if (Platform.isMacOS) {
    final home = Platform.environment['HOME'] ?? '';
    path = p.join(home, 'Library', 'Application Support', appName);
  } else {
    final xdg = Platform.environment['XDG_CONFIG_HOME'];
    final base = (xdg != null && xdg.isNotEmpty)
        ? xdg
        : p.join(Platform.environment['HOME'] ?? '', '.config');
    path = p.join(base, appName.toLowerCase());
  }
  Directory(path).createSync(recursive: true);
  return path;
}

String get configFile => p.join(getDirectoryConfig(), 'config.json');

Map<String, dynamic>? _configCache;

void ensureExecutable(String filePath) {
  if ((Platform.isLinux || Platform.isMacOS) && File(filePath).existsSync()) {
    try {
      Process.runSync('chmod', ['+x', filePath]);
    } catch (_) {}
  }
}

String getDefaultBundledPath(String tool) {
  final String baseDir;
  final exeDir = File(Platform.resolvedExecutable).parent.path;

  if (Directory(p.join(exeDir, 'assets')).existsSync()) {
    baseDir = exeDir;
  } else if (Directory(p.join(Directory.current.path, 'assets')).existsSync()) {
    baseDir = Directory.current.path;
  } else {
    var current = Directory(exeDir);
    String? found;
    for (int i = 0; i < 3; i++) {
      if (Directory(p.join(current.path, 'assets')).existsSync()) {
        found = current.path;
        break;
      }
      current = current.parent;
    }
    baseDir = found ?? Directory.current.path;
  }

  final String archFolder;
  final archStr = '${Platform.version} ${Platform.operatingSystem}'.toLowerCase();
  if (archStr.contains('aarch64') || archStr.contains('arm64')) {
    archFolder = 'arm64';
  } else {
    archFolder = 'x86_64';
  }

  if (tool == 'nkit') {
    String res;
    if (Platform.isWindows) {
      res = p.join(baseDir, 'assets', 'windows', 'nkit', 'nkit.exe');
    } else if (Platform.isMacOS) {
      res = p.join(baseDir, 'assets', 'macos', archFolder, 'nkit', 'nkit');
    } else {
      res = p.join(baseDir, 'assets', 'linux', archFolder, 'nkit', 'nkit');
    }
    if (File(res).existsSync()) {
      ensureExecutable(res);
      return res;
    }
  }

  final winNames = {
    'chdman': 'chdman.exe',
    'ecm': 'ecm.exe',
    'unecm': 'unecm.exe',
    'maxcso': 'maxcso.exe',
    'extract-xiso': 'extract-xiso.exe',
    'nodtool': 'nodtool.exe',
    'xdelta3': 'xdelta3.exe',
    'nkit': 'nkit.exe',
    'saturn-patcher': 'saturn-patcher.exe',
    'xgdtool': 'XGDTool.exe',
  };

  final unixNames = {
    'chdman': 'chdman',
    'ecm': 'ecm',
    'unecm': 'unecm',
    'maxcso': 'maxcso',
    'extract-xiso': 'extract-xiso',
    'nodtool': 'nodtool',
    'xdelta3': 'xdelta3',
    'nkit': 'nkit',
    'saturn-patcher': 'saturn-patcher',
    'xgdtool': 'XGDTool',
  };

  String bundled;
  if (Platform.isWindows) {
    final fname = winNames[tool] ?? '$tool.exe';
    bundled = p.join(baseDir, 'assets', 'windows', fname);
  } else if (Platform.isMacOS) {
    final fname = unixNames[tool] ?? tool;
    bundled = p.join(baseDir, 'assets', 'macos', archFolder, fname);
    if (!File(bundled).existsSync()) {
      bundled = p.join(baseDir, 'assets', 'macos', fname);
    }
  } else {
    final fname = unixNames[tool] ?? tool;
    bundled = p.join(baseDir, 'assets', 'linux', archFolder, fname);
    if (!File(bundled).existsSync()) {
      bundled = p.join(baseDir, 'assets', 'linux', fname);
    }
  }

  if (File(bundled).existsSync()) {
    ensureExecutable(bundled);
    return bundled;
  }

  final fallback = Platform.isWindows
      ? (winNames[tool] ?? tool)
      : (unixNames[tool] ?? tool);
  ensureExecutable(fallback);
  return fallback;
}

const Map<String, String> defaultConfig = {
  'chdman': '',
  'maxcso': '',
  'ecm': '',
  'unecm': '',
  'extract-xiso': '',
  'nodtool': '',
  'xdelta3': '',
  'nkit': '',
  'saturn-patcher': '',
  'xgdtool': '',
};

Map<String, dynamic> loadConfig() {
  if (_configCache != null) return _configCache!;
  final file = File(configFile);
  if (file.existsSync()) {
    try {
      final content = file.readAsStringSync();
      final Map<String, dynamic> config = jsonDecode(content);
      for (final k in defaultConfig.keys) {
        if (!config.containsKey(k)) {
          config[k] = '';
        }
      }
      _configCache = config;
      return _configCache!;
    } catch (_) {}
  }
  _configCache = Map<String, dynamic>.from(defaultConfig);
  return _configCache!;
}

bool saveConfig(Map<String, dynamic> config) {
  try {
    final file = File(configFile);
    file.writeAsStringSync(const JsonEncoder.withIndent('    ').convert(config));
    _configCache = null;
    return true;
  } catch (e) {
    stderr.writeln('[OpenROM] Warning: Could not save config: $e');
    return false;
  }
}

String getToolPath(String tool) {
  final config = loadConfig();
  final val = config[tool] as String? ?? '';
  if (val.isNotEmpty && (File(val).existsSync() || p.isAbsolute(val))) {
    ensureExecutable(val);
    return val;
  }
  return getDefaultBundledPath(tool);
}
