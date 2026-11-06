// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/theme_config.dart';

/// Paints [theme]'s wallpaper (if any) behind [child].
///
/// The wallpaper is drawn with [ThemeConfig.wallpaperOpacity] and, when
/// [ThemeConfig.wallpaperBlur] is non-zero, a [BackdropFilter] gaussian blur.
/// A missing or unreadable file degrades gracefully to the flat background
/// colour, so a skin that references a deleted wallpaper still renders.
class WallpaperBackground extends StatelessWidget {
  final ThemeConfig theme;
  final Widget child;

  const WallpaperBackground({
    super.key,
    required this.theme,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final path = theme.wallpaperPath;
    final file = path == null ? null : File(path);
    final hasWallpaper = file != null && file.existsSync();

    if (!hasWallpaper) {
      return ColoredBox(color: theme.background, child: child);
    }

    final blur = theme.wallpaperBlur.clamp(0.0, 20.0);
    final opacity = theme.wallpaperOpacity.clamp(0.0, 1.0);

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: theme.background),
        Positioned.fill(
          child: Opacity(
            opacity: opacity,
            child: Image.file(
              file,
              fit: BoxFit.cover,
              // A corrupt image must not crash the whole app shell.
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),
        if (blur > 0)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: const SizedBox.expand(),
            ),
          ),
        child,
      ],
    );
  }
}
