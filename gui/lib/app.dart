// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'package:flutter/material.dart';

import 'controllers/home_controller.dart';
import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'screens/about_screen.dart';
import 'screens/dreamcast_screen.dart';
import 'screens/home_screen.dart';
import 'screens/patcher_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/theme_editor_screen.dart';
import 'screens/tools_screen.dart';
import 'services/theme_service.dart';
import 'widgets/sidebar.dart';
import 'widgets/top_bar.dart';

class OpenROMApp extends StatefulWidget {
  final ThemeService themeService;
  final LocaleProvider localeProvider;
  final HomeController? homeController;

  OpenROMApp({
    super.key,
    required this.themeService,
    LocaleProvider? localeProvider,
    this.homeController,
  }) : localeProvider = localeProvider ?? LocaleProvider();

  @override
  State<OpenROMApp> createState() => _OpenROMAppState();
}

class _OpenROMAppState extends State<OpenROMApp> {
  int _selectedIndex = 0;
  late final HomeController _homeController;

  String _format = 'CHD';
  String _compression = 'Normal';
  bool _verify = false;
  String _outputDir = '';

  @override
  void initState() {
    super.initState();
    _homeController = widget.homeController ?? HomeController();
    widget.themeService.addListener(_onChanged);
    widget.localeProvider.addListener(_onChanged);
    _homeController.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.themeService.removeListener(_onChanged);
    widget.localeProvider.removeListener(_onChanged);
    _homeController.removeListener(_onChanged);
    if (widget.homeController == null) {
      _homeController.dispose();
    }
    super.dispose();
  }

  void _onChanged() {
    setState(() {});
  }

  void _onConvertPressed() {
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
      });
    }
    _homeController.startConversion(
      globalFormat: _format,
      compression: _compression,
      verify: _verify,
      outputDir: _outputDir,
    );
  }

  void _onAddFilesPressed() {
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
      });
    }
    _homeController.pickFiles();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.themeService.currentTheme;

    final int fileCount = _homeController.fileCount;
    final bool isConverting = _homeController.isConverting;

    final settingsWidget = SettingsScreen(
      theme: theme,
      themeService: widget.themeService,
      localeProvider: widget.localeProvider,
      onSettingsChanged: (format, compression, verify, outputDir, sameFolder) {
        setState(() {
          _format = format;
          _compression = compression;
          _verify = verify;
          _outputDir = outputDir;
        });
      },
    );

    return MaterialApp(
      title: 'OpenROM',
      debugShowCheckedModeBanner: false,
      locale: widget.localeProvider.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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
                      index: _selectedIndex,
                      children: [
                        HomeScreen(
                          theme: theme,
                          controller: _homeController,
                        ),
                        PatcherScreen(theme: theme),
                        ToolsScreen(theme: theme),
                        DreamcastScreen(theme: theme),
                        settingsWidget,
                        AboutScreen(theme: theme),
                        ThemeEditorScreen(
                          theme: theme,
                          themeService: widget.themeService,
                        ),
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
