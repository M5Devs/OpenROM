// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3 + Commons Clause

import 'package:flutter/material.dart';
import '../models/theme_config.dart';
import '../services/core_bridge.dart';

class AboutScreen extends StatefulWidget {
  final ThemeConfig theme;

  const AboutScreen({super.key, required this.theme});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = 'Loading...';

  @override
  void initState() {
    super.initState();
    CoreBridge.getVersion().then((v) {
      if (mounted) setState(() => _version = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hexagon_outlined, size: 80, color: theme.accent),
            const SizedBox(height: 16),
            Text(
              'OpenROM',
              style: TextStyle(
                fontFamily: theme.fontFamily,
                color: theme.textPrimary,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Universal ROM Compression Suite',
              style: TextStyle(color: theme.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              _version,
              style: TextStyle(color: theme.accent, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 32),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(theme.borderRadius),
                ),
                child: Column(
                  children: [
                    Text(
                      'Built by M5 Dev',
                      style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'OpenROM converts ROM files across popular formats (ISO, CHD, CSO, ECM, RVZ, XISO) '
                      'using bundled CLI utilities (chdman, maxcso, ecm, nodtool, extract-xiso).',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 12),
                    Text(
                      'License: GPL v3 + Commons Clause',
                      style: TextStyle(color: theme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
