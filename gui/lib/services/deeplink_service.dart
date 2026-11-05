// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:openrom_core/openrom_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Receives `openrom://` links from every entry point and turns them into a
/// single stream of [DeepLinkTarget]s.
///
/// Links arrive by three routes, all of which land here:
///  * **Cold start** — the OS launches the app with the URL as an argument
///    (Windows registry, Linux `.desktop` `%u`, macOS `Info.plist`). Handled
///    from `main(args)` and, on Android, via `getLaunchUrl`.
///  * **Warm start** — the app is already running and the OS hands the URL to
///    the native host, which forwards it over the `openrom.deeplink` channel.
///  * **Missed links** — when no listener is attached yet (or the app was
///    closed mid-link) the target is persisted so it can be replayed.
class DeepLinkService {
  static const MethodChannel _channel =
      MethodChannel('com.m5devs.openrom/deeplink');

  static const String _pendingKey = 'openrom_pending_deeplink';

  final _controller = StreamController<DeepLinkTarget>.broadcast();

  DeepLinkTarget? _pending;
  bool _started = false;

  /// Broadcast stream of incoming deep links.
  Stream<DeepLinkTarget> get links => _controller.stream;

  /// The most recent target that no listener has consumed yet.
  DeepLinkTarget? get pending => _pending;

  /// Wires up the native channel and drains any link the app was launched with.
  ///
  /// Safe to call more than once; subsequent calls are no-ops.
  Future<void> start({List<String> launchArgs = const []}) async {
    if (_started) return;
    _started = true;

    _channel.setMethodCallHandler(_onNativeCall);

    // 1. Cold start via process arguments (desktop).
    final fromArgs = DeepLink.fromArguments(launchArgs);
    if (fromArgs != null) _emit(fromArgs);

    // 2. A link persisted before the UI was ready.
    final persisted = await _readPending();
    if (persisted != null && persisted.raw != (fromArgs?.raw ?? '')) {
      _emit(persisted);
    }

    // 3. Cold start on platforms that hand the URL to the native host
    //    (Android intent, macOS `openURLs:`).
    try {
      final url = await _channel.invokeMethod<String>('getLaunchUrl');
      if (url != null && url.isNotEmpty) {
        final target = DeepLink.parse(url);
        if (target != null && target.raw != _pending?.raw) _emit(target);
      }
    } catch (_) {
      // No native handler on this platform; arguments already covered it.
    }
  }

  Future<void> _onNativeCall(MethodCall call) async {
    if (call.method != 'openrom.deeplink' && call.method != 'openrom.url') {
      return;
    }
    final raw = call.arguments?.toString() ?? '';
    final target = DeepLink.parse(raw);
    if (target != null) _emit(target);
  }

  /// Marks [target] as handled so it is not replayed on the next launch.
  Future<void> consume(DeepLinkTarget target) async {
    if (_pending?.raw == target.raw) _pending = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_pendingKey) == target.raw) {
        await prefs.remove(_pendingKey);
      }
    } catch (_) {}
  }

  /// Parses and stores a raw link that arrived before the UI was ready.
  Future<void> handleRaw(String raw) async {
    final target = DeepLink.parse(raw);
    if (target == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pendingKey, target.raw);
    } catch (_) {}
    _emit(target);
  }

  void _emit(DeepLinkTarget target) {
    _pending = target;
    if (!_controller.isClosed) _controller.add(target);
  }

  Future<DeepLinkTarget?> _readPending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_pendingKey);
      if (raw == null || raw.isEmpty) return null;
      return DeepLink.parse(raw);
    } catch (e) {
      debugPrint('DeepLink: failed to read pending link: $e');
      return null;
    }
  }

  void dispose() {
    _channel.setMethodCallHandler(null);
    _controller.close();
  }
}
