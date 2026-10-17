// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'controllers/home_controller.dart';
import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'screens/about_screen.dart';
import 'screens/dreamcast_screen.dart';
import 'screens/home_screen.dart';
import 'screens/patcher_screen.dart';
import 'screens/plugins_screen.dart';
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
  String _audioCodec = 'flac';

  static const List<int> _mobileScreenIndices = [0, 1, 2, 4, 5];

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
      audioCodec: _audioCodec,
      onPromptMedia: (job) async {
        return await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Unrecognized Media Type'),
            content: Text(
              'Unrecognized Media Type: Is this game a CD or DVD?\n\nFile: ${job.romFile.filename}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop('cd'),
                child: const Text('CD'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop('dvd'),
                child: const Text('DVD'),
              ),
            ],
          ),
        );
      },
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
      onSettingsChanged:
          (format, compression, verify, outputDir, sameFolder, audioCodec) {
        setState(() {
          _format = format;
          _compression = compression;
          _verify = verify;
          _outputDir = outputDir;
          _audioCodec = audioCodec;
        });
      },
    );

    final screens = [
      HomeScreen(theme: theme, controller: _homeController),
      PatcherScreen(theme: theme),
      ToolsScreen(theme: theme),
      DreamcastScreen(theme: theme),
      PluginsScreen(theme: theme),
      settingsWidget,
      AboutScreen(theme: theme),
      ThemeEditorScreen(
        theme: theme,
        themeService: widget.themeService,
      ),
    ];

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
      home: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 650;
          final isMobile = isNarrow ||
              defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS;

          if (isMobile) {
            final mobileCurrentIndex =
                _mobileScreenIndices.contains(_selectedIndex)
                    ? _mobileScreenIndices.indexOf(_selectedIndex)
                    : 0;

            return Scaffold(
              backgroundColor: theme.background,
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: TopBar(
                  theme: theme,
                  fileCount: fileCount,
                  isConverting: isConverting,
                  onConvertPressed: _onConvertPressed,
                  onAddFilesPressed: _onAddFilesPressed,
                ),
              ),
              body: IndexedStack(
                index: _selectedIndex,
                children: screens,
              ),
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: mobileCurrentIndex,
                onTap: (int index) {
                  setState(() {
                    _selectedIndex = _mobileScreenIndices[index];
                  });
                },
                backgroundColor: theme.surface,
                selectedItemColor: theme.accent,
                unselectedItemColor: theme.textSecondary,
                type: BottomNavigationBarType.fixed,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.sync_alt_outlined),
                    activeIcon: Icon(Icons.sync_alt),
                    label: 'Convert',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.healing_outlined),
                    activeIcon: Icon(Icons.healing),
                    label: 'Patch',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.construction_outlined),
                    activeIcon: Icon(Icons.construction),
                    label: 'Tools',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.extension_outlined),
                    activeIcon: Icon(Icons.extension),
                    label: 'Plugins',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings_outlined),
                    activeIcon: Icon(Icons.settings),
                    label: 'Settings',
                  ),
                ],
              ),
            );
          }

          return Scaffold(
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
                          children: screens,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
