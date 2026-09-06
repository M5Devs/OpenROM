// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3 + Commons Clause

import 'package:flutter/material.dart';
import '../models/conversion_job.dart';
import '../models/theme_config.dart';

class RomCard extends StatefulWidget {
  final ConversionJob job;
  final ThemeConfig theme;
  final VoidCallback onDelete;

  const RomCard({
    super.key,
    required this.job,
    required this.theme,
    required this.onDelete,
  });

  @override
  State<RomCard> createState() => _RomCardState();
}

class _RomCardState extends State<RomCard> {
  bool _isHovered = false;

  LinearGradient _getPlatformGradient(String platform) {
    final p = platform.toUpperCase();
    if (p.contains('PS1')) {
      return const LinearGradient(colors: [Color(0xff2d3748), Color(0xff1a202c)]);
    } else if (p.contains('PS2')) {
      return const LinearGradient(colors: [Color(0xff1e3a8a), Color(0xff3b0764)]);
    } else if (p.contains('GAMECUBE') || p.contains('GC')) {
      return const LinearGradient(colors: [Color(0xff4c1d95), Color(0xff1e1b4b)]);
    } else if (p.contains('XBOX')) {
      return const LinearGradient(colors: [Color(0xff14532d), Color(0xff052e16)]);
    } else if (p.contains('PSP')) {
      return const LinearGradient(colors: [Color(0xff0891b2), Color(0xff164e63)]);
    } else if (p.contains('DREAMCAST')) {
      return const LinearGradient(colors: [Color(0xffc2410c), Color(0xff431407)]);
    }
    return LinearGradient(colors: [
      widget.theme.cardBg,
      widget.theme.surface,
    ]);
  }

  Color _hexToColor(String hex) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return widget.theme.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rom = widget.job.romFile;
    final badgeColor = _hexToColor(rom.badgeColor);
    final gradient = _getPlatformGradient(rom.platform);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(widget.theme.borderRadius),
          border: Border.all(
            color: _isHovered ? widget.theme.accent : widget.theme.surface,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isHovered ? 0.4 : 0.2),
              blurRadius: _isHovered ? 12 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.theme.borderRadius),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Platform badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.sports_esports, color: widget.theme.textPrimary, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            rom.platform,
                            style: TextStyle(
                              color: widget.theme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title & Filename
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rom.filename,
                            style: TextStyle(
                              color: widget.theme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Status: ${widget.job.statusText}',
                            style: TextStyle(
                              color: widget.job.status == JobStatus.failed
                                  ? Colors.redAccent
                                  : (widget.job.status == JobStatus.done
                                      ? Colors.greenAccent
                                      : widget.theme.textSecondary),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Format badge & Size
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${rom.format} → ${widget.job.targetFormat}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          rom.sizeStr,
                          style: TextStyle(
                            color: widget.theme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    // Delete button on hover
                    if (_isHovered)
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                        onPressed: widget.onDelete,
                        tooltip: 'Remove ROM',
                      )
                    else
                      const SizedBox(width: 32),
                  ],
                ),
              ),
              // Slim progress bar at bottom edge
              if (widget.job.status == JobStatus.converting)
                LinearProgressIndicator(
                  value: widget.job.progress / 100.0,
                  backgroundColor: Colors.black26,
                  color: widget.theme.accent,
                  minHeight: 4,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
