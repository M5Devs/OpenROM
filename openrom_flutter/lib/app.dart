// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3 + Commons Clause

import 'package:flutter/material.dart';
import 'screens/about_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'services/theme_service.dart';
import 'widgets/sidebar.dart';
import 'widgets/top_bar.dart';

class OpenROMApp extends StatefulWidget {
  final ThemeService themeService;

  const OpenROMApp({super.key, required this.themeService});

  @override
  State<OpenROMApp> createState() => _OpenROMAppState();
}

class _OpenROMAppState extends State<OpenROMApp> {
  int _selectedIndex = 0;
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();

  String _format = 'CHD';
  String _compression = 'Normal';
  bool _verify = false;
  String _outputDir = '';

  @override
  void initState() {
    super.initState();
    widget.themeService.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    widget.themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  void _onConvertPressed() {
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _homeKey.currentState?.startConversion(
        globalFormat: _format,
        compression: _compression,
        verify: _verify,
        outputDir: _outputDir,
      );
    });
  }

  void _onAddFilesPressed() {
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _homeKey.currentState?.pickFiles();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.themeService.currentTheme;

    final int fileCount = _homeKey.currentState?.fileCount ?? 0;
    final bool isConverting = _homeKey.currentState?.isConverting ?? false;

    return MaterialApp(
      title: 'OpenROM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: theme.background,
        colorScheme: ColorScheme.dark(
          surface: theme.surface,
          primary: theme.accent,
        ),
      ),
      home: Scaffold(
        backgroundColor: theme.background,
        body: Row(
          children: [
            Sidebar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              theme: theme,
            ),
            Expanded(
              child: Column(
                children: [
                  TopBar(
                    theme: theme,
                    fileCount: fileCount,
                    isConverting: isConverting,
                    onConvertPressed: _onConvertPressed,
                    onAddFilesPressed: _onAddFilesPressed,
                  ),
                  Expanded(
                    child: IndexedStack(
                      index: _selectedIndex == 2 ? 1 : _selectedIndex,
                      children: [
                        HomeScreen(key: _homeKey, theme: theme),
                        SettingsScreen(
                          theme: theme,
                          themeService: widget.themeService,
                          onSettingsChanged: (format, compression, verify, outputDir, sameFolder) {
                            setState(() {
                              _format = format;
                              _compression = compression;
                              _verify = verify;
                              _outputDir = outputDir;
                            });
                          },
                        ),
                        AboutScreen(theme: theme),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
