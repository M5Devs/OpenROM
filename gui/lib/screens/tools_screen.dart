// OpenROM — Universal ROM Compression Suite · M5 Dev | GPL v3
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/theme_config.dart';
import 'tools/tabs/bin_merger_tab.dart';
import 'tools/tabs/compressor_tab.dart';
import 'tools/tabs/cue_editor_tab.dart';
import 'tools/tabs/cue_generator_tab.dart';
import 'tools/tabs/header_remover_tab.dart';
import 'tools/tabs/m3u_tab.dart';
import 'tools/tabs/mame_auditor_tab.dart';
import 'tools/tabs/one_g_one_r_tab.dart';
import 'tools/tabs/rom_hasher_tab.dart';
import 'tools/tabs/rom_renamer_tab.dart';
import 'tools/tabs/watch_folder_tab.dart';

class ToolsScreen extends StatefulWidget {
  final ThemeConfig theme;
  const ToolsScreen({super.key, required this.theme});
  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 11, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(children: [
        Container(
          color: widget.theme.sidebarBg,
          child: TabBar(
            controller: _tabController,
            indicatorColor: widget.theme.accent,
            labelColor: widget.theme.accent,
            unselectedLabelColor: widget.theme.textSecondary,
            tabs: [
              Tab(
                  icon: const Icon(Icons.archive_outlined),
                  text: l10n.compressorTitle),
              Tab(
                  icon: const Icon(Icons.playlist_add_outlined),
                  text: l10n.m3uTitle),
              Tab(
                  icon: const Icon(Icons.description_outlined),
                  text: l10n.cueGeneratorTitle),
              Tab(
                  icon: const Icon(Icons.link_outlined),
                  text: l10n.binMergerTitle),
              Tab(
                  icon: const Icon(Icons.content_cut_outlined),
                  text: l10n.headerRemoverTitle),
              Tab(
                  icon: const Icon(Icons.edit_document),
                  text: l10n.toolsTabCue),
              Tab(
                  icon: const Icon(Icons.drive_file_rename_outline),
                  text: l10n.toolsTabRenamer),
              Tab(
                  icon: const Icon(Icons.cleaning_services_outlined),
                  text: l10n.toolsTab1g1r),
              Tab(
                  icon: const Icon(Icons.fingerprint),
                  text: l10n.toolsTabHasher),
              Tab(
                  icon: const Icon(Icons.folder_shared_outlined),
                  text: l10n.toolsWatchTitle),
              Tab(
                  icon: const Icon(Icons.videogame_asset_outlined),
                  text: l10n.toolsArcadeTitle),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              CompressorTab(theme: widget.theme),
              M3uTab(theme: widget.theme),
              CueGeneratorTab(theme: widget.theme),
              BinMergerTab(theme: widget.theme),
              HeaderRemoverTab(theme: widget.theme),
              CueEditorTab(theme: widget.theme),
              RomRenamerTab(theme: widget.theme),
              OneGOneRCleanerTab(theme: widget.theme),
              RomHasherTab(theme: widget.theme),
              WatchFolderTab(theme: widget.theme),
              MameAuditorTab(theme: widget.theme),
            ],
          ),
        ),
      ]),
    );
  }
}
