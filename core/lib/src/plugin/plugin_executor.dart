// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import 'plugin_manifest.dart';
import 'plugin_registry.dart';

/// Outcome of running a plugin executable.
class PluginRunResult {
  final bool success;
  final int? exitCode;
  final String? error;

  const PluginRunResult.success(this.exitCode)
      : success = true,
        error = null;

  const PluginRunResult.failure(this.error, {this.exitCode}) : success = false;

  @override
  String toString() => success
      ? 'PluginRunResult.success($exitCode)'
      : 'PluginRunResult.failure($error)';
}

/// Executes plugin binaries safely.
///
/// Security properties:
///  * **No shell.** Arguments are passed as a pre-split array to
///    `Process.start(exe, argv)`; there is no string interpolation, no quoting,
///    and no `sh -c`. Paths with quotes/spaces/`;`/`$()` cannot escape into a
///    command.
///  * **Containment.** The resolved executable must live inside the plugin's
///    own directory (real-path prefix check), defeating `../` traversal and
///    symlink escapes.
///  * **Integrity.** The binary's SHA-256 is re-verified immediately before
///    execution (defense in depth on top of install-time verification).
///  * **Bounded.** Optional timeout kills a runaway process.
class PluginExecutor {
  /// Absolute path of the plugins root directory.
  final String pluginsDir;

  PluginExecutor({required this.pluginsDir});

  /// Runs [conversion] for the given input/output.
  ///
  /// [inputPath], [outputPath], [outputDir] and [cuePath] are resolved by the
  /// caller; the executor only maps them onto the plugin's declared argument
  /// vector. Returns a [PluginRunResult] and never throws for expected tool
  /// failures.
  Future<PluginRunResult> run({
    required RegisteredConversion conversion,
    required String inputPath,
    required String outputPath,
    required String outputDir,
    String? cuePath,
    required void Function(String message) onLog,
    void Function(double percent)? onProgress,
    double? Function(String line)? parseProgress,
  }) async {
    final manifest = conversion.manifest;

    if (manifest.execution.kind != PluginExecutionKind.process) {
      return PluginRunResult.failure(
        'Plugin "${manifest.id}" uses an unsupported execution kind '
        '"${manifest.execution.kind.name}".',
      );
    }

    final env = manifest.execution.currentEnvironment;
    if (env == null) {
      return PluginRunResult.failure(
        'Plugin "${manifest.id}" has no build for platform '
        '"${currentPlatformKey()}".',
      );
    }

    // Resolve the executable strictly inside the plugin directory.
    final pluginDir = p.normalize(p.absolute(p.join(pluginsDir, manifest.id)));
    final executable = _joinUnder(pluginDir, env.executable);
    if (executable == null) {
      return PluginRunResult.failure(
        'Plugin "${manifest.id}" executable path "${env.executable}" escapes '
        'the plugin directory.',
      );
    }

    final exeFile = File(executable);
    if (!exeFile.existsSync()) {
      return PluginRunResult.failure(
        'Plugin "${manifest.id}" executable not found: $executable',
      );
    }

    // Containment by *real* path: resolves `..` and symlinks, so a link inside
    // the plugin directory pointing outside is refused.
    final String realPluginDir;
    final String realExecutable;
    try {
      realPluginDir = Directory(pluginDir).resolveSymbolicLinksSync();
      realExecutable = exeFile.resolveSymbolicLinksSync();
    } on FileSystemException catch (e) {
      return PluginRunResult.failure(
        'Plugin "${manifest.id}" executable could not be resolved: '
        '${e.message}',
      );
    }
    if (!_isInside(realPluginDir, realExecutable)) {
      return PluginRunResult.failure(
        'Plugin "${manifest.id}" executable path "${env.executable}" escapes '
        'the plugin directory.',
      );
    }

    // Re-verify integrity right before execution.
    if (env.sha256.isNotEmpty) {
      final actual = sha256.convert(exeFile.readAsBytesSync()).toString();
      if (actual.toLowerCase() != env.sha256.trim().toLowerCase()) {
        return PluginRunResult.failure(
          'Plugin "${manifest.id}" failed its integrity check '
          '(expected ${env.sha256}, got $actual).',
        );
      }
    }

    _ensureExecutable(executable);

    // Build the argv from the structured argument vector.
    final values = <PluginArgKind, String>{
      PluginArgKind.executable: executable,
      PluginArgKind.input: p.absolute(inputPath),
      PluginArgKind.output: p.absolute(outputPath),
      PluginArgKind.outputDir: p.absolute(outputDir),
      PluginArgKind.inputName: p.basename(inputPath),
      PluginArgKind.outputName: p.basename(outputPath),
      if (cuePath != null && cuePath.isNotEmpty) PluginArgKind.cue: cuePath,
    };

    final argv = <String>[];
    for (final arg in manifest.execution.args) {
      final resolved = arg.resolve(values);
      if (resolved == null) {
        return PluginRunResult.failure(
          'Plugin "${manifest.id}" argument "${arg.kind.name}" could not be '
          'resolved for this job.',
        );
      }
      // The `executable` token names the program itself. `Process.start`
      // already receives it as its own argument, so it must not also appear in
      // the argv handed to the tool (Dart's `arguments` exclude argv[0]).
      if (arg.kind == PluginArgKind.executable) continue;
      argv.add(resolved);
    }

    onLog('  cmd: ${[p.basename(executable), ...argv].join(' ')}');

    final successCodes = manifest.execution.successExitCodes;
    final timeout = manifest.execution.timeout;

    try {
      final process = await Process.start(
        executable,
        argv,
        environment: {
          if (manifest.execution.environment.isNotEmpty)
            ...manifest.execution.environment,
        },
        includeParentEnvironment: true,
        workingDirectory: pluginDir,
      );

      var timedOut = false;
      Timer? killTimer;
      if (timeout > Duration.zero) {
        killTimer = Timer(timeout, () {
          timedOut = true;
          onLog(
              '  ⏱ Plugin exceeded its ${timeout.inSeconds}s timeout; terminating.');
          process.kill(ProcessSignal.sigkill);
        });
      }

      final stderrBuffer = StringBuffer();
      final lastLine = <String>[''];

      void handle(String line, {bool isStderr = false}) {
        final trimmed = line.trimRight();
        if (trimmed.isEmpty) return;
        lastLine[0] = trimmed;
        onLog('  $trimmed');
        if (isStderr) stderrBuffer.writeln(trimmed);
        if (onProgress != null && parseProgress != null) {
          final pct = parseProgress(trimmed);
          if (pct != null) onProgress(pct);
        }
      }

      final stdoutDone = _pump(process.stdout, (l) => handle(l));
      final stderrDone =
          _pump(process.stderr, (l) => handle(l, isStderr: true));
      await Future.wait([stdoutDone, stderrDone]);
      final exitCode = await process.exitCode;
      killTimer?.cancel();

      if (timedOut) {
        return PluginRunResult.failure(
          'Plugin "${manifest.id}" timed out after ${timeout.inSeconds}s.',
          exitCode: exitCode,
        );
      }

      if (successCodes.contains(exitCode)) {
        onProgress?.call(100);
        return PluginRunResult.success(exitCode);
      }

      final details = stderrBuffer.isNotEmpty
          ? stderrBuffer.toString().trim()
          : (lastLine[0].isNotEmpty ? lastLine[0] : 'no output');
      return PluginRunResult.failure(
        'Plugin "${manifest.id}" exited with code $exitCode: $details',
        exitCode: exitCode,
      );
    } on ProcessException catch (e) {
      return PluginRunResult.failure('Plugin launch failed: ${e.message}');
    } catch (e) {
      return PluginRunResult.failure('Plugin execution error: $e');
    }
  }

  /// Streams [stream] line by line, invoking [onLine] for each complete line.
  Future<void> _pump(
    Stream<List<int>> stream,
    void Function(String line) onLine,
  ) async {
    var buffer = '';
    await for (final chunk in stream.transform(utf8.decoder)) {
      buffer += chunk;
      final parts = buffer.split(RegExp(r'[\r\n]+'));
      for (var i = 0; i < parts.length - 1; i++) {
        onLine(parts[i]);
      }
      buffer = parts.last;
    }
    if (buffer.isNotEmpty) onLine(buffer);
  }

  /// Returns the absolute path of [relative] resolved lexically under [root],
  /// or `null` when it would escape the root (zip-slip / `..` / absolute path).
  ///
  /// This is a *lexical* check only. Callers that guard execution must also
  /// verify the real path via [_isInside] after resolving symbolic links.
  static String? _joinUnder(String root, String relative) {
    if (relative.trim().isEmpty) return null;
    if (p.isAbsolute(relative)) return null;
    final resolved = p.normalize(p.absolute(p.join(root, relative)));
    final normalizedRoot = p.normalize(p.absolute(root));
    if (resolved != normalizedRoot &&
        !resolved.startsWith(normalizedRoot + p.separator)) {
      return null;
    }
    return resolved;
  }

  /// Whether the real path [realChild] lies strictly inside [realRoot].
  static bool _isInside(String realRoot, String realChild) {
    if (realChild == realRoot) return true;
    return realChild.startsWith(
      realRoot.endsWith(p.separator) ? realRoot : realRoot + p.separator,
    );
  }

  static void _ensureExecutable(String path) {
    if (!Platform.isWindows) {
      try {
        Process.runSync('chmod', ['+x', path]);
      } catch (_) {}
    }
  }
}
