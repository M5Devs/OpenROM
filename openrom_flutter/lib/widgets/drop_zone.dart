// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3 + Commons Clause

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import '../models/theme_config.dart';

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
                    Icon(
                      Icons.hexagon_outlined,
                      size: 96,
                      color: widget.theme.accent,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Drop ROM files here',
                      style: TextStyle(
                        fontFamily: widget.theme.fontFamily,
                        color: widget.theme.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Supports ISO, BIN, CUE, GDI, CHD, CSO, ECM, RVZ, XISO, WBFS...',
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
