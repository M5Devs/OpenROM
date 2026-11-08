// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'package:flutter/material.dart';

/// Asset paths for the animated ROMéo mascot GIFs bundled under
/// `assets/images/romeo/` and registered in `pubspec.yaml`.
abstract class RomeoAssets {
  static const String idle = 'assets/images/romeo/romeo-idle.gif';
  static const String working = 'assets/images/romeo/romeo-working.gif';
  static const String success = 'assets/images/romeo/romeo-success.gif';
  static const String error = 'assets/images/romeo/romeo-error.gif';
  static const String search = 'assets/images/romeo/romeo-search.gif';
}

/// Renders an animated ROMéo mascot GIF as a square of [size] logical pixels.
///
/// GIF frames loop automatically because [Image.asset] decodes animated images
/// natively. A missing or corrupt asset degrades to [fallback] (or a neutral
/// robot icon) instead of throwing.
class RomeoMascot extends StatelessWidget {
  final String asset;
  final double size;
  final Widget? fallback;

  const RomeoMascot({
    super.key,
    required this.asset,
    this.size = 100,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          fallback ?? Icon(Icons.smart_toy_outlined, size: size),
    );
  }
}
