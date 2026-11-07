// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/theme_config.dart';

/// The default (no-skin) dropzone illustration, shown while dragging files in.
const IconData kDefaultDropzoneIcon = Icons.hexagon_outlined;

/// Returns the active skin's custom dropzone illustration, or null when the
/// skin has none (or the file has gone missing).
File? skinDropzoneArt(ThemeConfig theme) {
  final path = theme.dropzonePath;
  if (path == null || path.isEmpty) return null;
  final file = File(path);
  return file.existsSync() ? file : null;
}

/// Renders the skin's dropzone artwork at [size], falling back to
/// [kDefaultDropzoneIcon]. Animated GIF/WebP artwork loops automatically
/// because [Image.file] decodes animated images natively.
class DropzoneArtwork extends StatelessWidget {
  final ThemeConfig theme;
  final double size;

  const DropzoneArtwork({
    super.key,
    required this.theme,
    this.size = 96,
  });

  @override
  Widget build(BuildContext context) {
    final art = skinDropzoneArt(theme);
    if (art == null) {
      return Icon(kDefaultDropzoneIcon, size: size, color: theme.accent);
    }
    return Image.file(
      art,
      width: size,
      height: size,
      fit: BoxFit.contain,
      // A corrupt illustration must not crash the drop overlay.
      errorBuilder: (_, __, ___) =>
          Icon(kDefaultDropzoneIcon, size: size, color: theme.accent),
    );
  }
}

class DropZone extends StatefulWidget {
  final Widget child;
  final Function(List<String> paths) onFilesDropped;
  final ThemeConfig theme;

  const DropZone({
    super.key,
    required this.child,
    required this.onFilesDropped,
    required this.theme,
  });

  @override
  State<DropZone> createState() => _DropZoneState();
}

class _DropZoneState extends State<DropZone> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return DropTarget(
      onDragEntered: (details) => setState(() => _isDragging = true),
      onDragExited: (details) => setState(() => _isDragging = false),
      onDragDone: (details) async {
        setState(() => _isDragging = false);
        final paths = details.files.map((f) => f.path).toList();
        if (paths.isNotEmpty) {
          widget.onFilesDropped(paths);
        }
      },
      child: Stack(
        children: [
          widget.child,
          if (_isDragging)
            Container(
              color: Colors.black.withValues(alpha: 0.85),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DropzoneArtwork(theme: widget.theme, size: 96),
                    const SizedBox(height: 20),
                    Text(
                      l10n.dropZoneHint,
                      style: TextStyle(
                        fontFamily: widget.theme.fontFamily,
                        color: widget.theme.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.dropZoneSubHint,
                      style: TextStyle(
                        color: widget.theme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
