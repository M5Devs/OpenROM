// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:async';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:openrom_core/openrom_core.dart';

import '../controllers/plugin_builder_controller.dart';
import '../controllers/plugin_controller.dart';
import '../models/theme_config.dart';
import '../services/deeplink_service.dart';
import '../widgets/deep_link_dialog.dart';
import '../widgets/orplug_builder_studio.dart';
import '../widgets/storefront_view.dart';

class PluginsScreen extends StatefulWidget {
  final ThemeConfig theme;
  final PluginController? controller;
  final PluginBuilderController? builderController;
  final DeepLinkService? deepLinkService;

  const PluginsScreen({
    super.key,
    required this.theme,
    this.controller,
    this.builderController,
    this.deepLinkService,
  });

  @override
  State<PluginsScreen> createState() => _PluginsScreenState();
}

class _PluginsScreenState extends State<PluginsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final PluginController _controller;
  StreamSubscription<DeepLinkTarget>? _deepLinkSub;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _controller = widget.controller ?? PluginController();
    _controller.addListener(_onControllerChanged);
    _controller.loadInstalledPlugins();
    _controller.fetchLiveStore();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _deepLinkSub?.cancel();
    _tabController.dispose();
    _controller.removeListener(_onControllerChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  /// Handles `openrom://` links by resolving them against the catalogue and
  /// asking the user to confirm before anything is downloaded.
  void _initDeepLinks() {
    final service = widget.deepLinkService;
    if (service == null) return;
    _deepLinkSub = service.links.listen(_onDeepLink);
    final pending = service.pending;
    if (pending != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onDeepLink(pending));
    }
  }

  Future<void> _onDeepLink(DeepLinkTarget target) async {
    final service = widget.deepLinkService;
    await service?.consume(target);
    if (!mounted) return;

    // Make sure the catalogue is loaded before resolving the id.
    if (!_controller.storeFetchAttempted || _controller.storeListings.isEmpty) {
      await _controller.fetchLiveStore();
      if (!mounted) return;
    }

    final listing = _controller.storeListings
        .where((l) => l.id == target.id)
        .cast<StoreListing?>()
        .firstWhere((_) => true, orElse: () => null);

    // Bring the store tab forward so the result is visible either way.
    if (_tabController.index != 1) {
      _tabController.animateTo(1);
    }

    if (listing == null) {
      await showDeepLinkNotFoundDialog(
        context: context,
        theme: widget.theme,
        target: target,
      );
      return;
    }

    if (_controller.isPluginInstalled(listing.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${listing.name} is already installed')),
      );
      return;
    }

    final confirmed = await showDeepLinkInstallDialog(
      context: context,
      theme: widget.theme,
      listing: listing,
    );
    if (!confirmed || !mounted) return;

    final ok = await _controller.installListing(listing);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? '${listing.name} installed'
            : _controller.errorMessage ?? 'Install failed'),
      ),
    );
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Color _parseHexColor(String hex, Color fallback) {
    try {
      var str = hex.replaceAll('#', '');
      if (str.length == 6) {
        str = 'FF$str';
      }
      return Color(int.parse(str, radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Column(
      children: [
        if (_controller.isLoading)
          LinearProgressIndicator(
            backgroundColor: theme.surface,
            color: theme.accent,
            minHeight: 3,
          ),
        Container(
          color: theme.surface,
          child: TabBar(
            controller: _tabController,
            indicatorColor: theme.accent,
            labelColor: theme.accent,
            unselectedLabelColor: theme.textSecondary,
            tabs: const [
              Tab(
                icon: Icon(Icons.extension_outlined),
                text: 'Installed Plugins 📦',
              ),
              Tab(
                icon: Icon(Icons.storefront_outlined),
                text: 'Plugin Store 🌐🛒',
              ),
              Tab(
                icon: Icon(Icons.handyman_outlined),
                text: 'Create / Studio 🛠️',
              ),
            ],
          ),
        ),
        if (_controller.errorMessage != null)
          Container(
            width: double.infinity,
            color: Colors.red.shade900.withValues(alpha: 0.8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _controller.errorMessage!,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 18),
                  onPressed: () => _controller.clearError(),
                ),
              ],
            ),
          ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildInstalledTab(theme),
              StorefrontView(
                theme: theme,
                controller: _controller,
              ),
              OrplugBuilderStudio(
                theme: theme,
                controller: widget.builderController,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInstalledTab(ThemeConfig theme) {
    return DropTarget(
      onDragEntered: (details) => setState(() => _isDragging = true),
      onDragExited: (details) => setState(() => _isDragging = false),
      onDragDone: (details) async {
        setState(() => _isDragging = false);
        for (final file in details.files) {
          if (file.path.endsWith('.orplug') || file.path.endsWith('.zip')) {
            await _controller.installPluginFromPath(file.path);
          }
        }
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Drag & Drop Box
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: _isDragging
                  ? theme.accent.withValues(alpha: 0.15)
                  : theme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isDragging ? theme.accent : theme.cardBg,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 44,
                  color: _isDragging ? theme.accent : theme.textSecondary,
                ),
                const SizedBox(height: 10),
                Text(
                  'Drag & Drop .orplug Archive Here',
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Install custom ROM tools, extensions, and formats',
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.accent,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(160, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _controller.pickAndInstallPlugin(),
                  icon: const Icon(Icons.folder_open),
                  label: const Text(
                    'Browse .orplug File',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Installed Plugins (${_controller.installedPlugins.length})',
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          if (_controller.installedPlugins.isEmpty)
            _buildEmptyState(theme)
          else
            ..._controller.installedPlugins.map(
              (plugin) => _buildInstalledCard(plugin, theme),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeConfig theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.extension_off_outlined,
            size: 56,
            color: theme.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No Plugins Installed Yet',
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Drop an .orplug package above or explore community plugins in the Plugin Store.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstalledCard(PluginManifest plugin, ThemeConfig theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.cardBg,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.extension,
                  color: theme.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            plugin.name,
                            style: TextStyle(
                              color: theme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.cardBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'v${plugin.version}',
                            style: TextStyle(
                              color: theme.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'by ${plugin.author}',
                      style: TextStyle(
                        color: theme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  minimumSize: const Size(100, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => _confirmUninstall(plugin, theme),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Uninstall'),
              ),
            ],
          ),
          if (plugin.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              plugin.description,
              style: TextStyle(
                color: theme.textPrimary.withValues(alpha: 0.9),
                fontSize: 13,
              ),
            ),
          ],
          if (plugin.extensions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: plugin.extensions.map((ext) {
                final badgeColor = _parseHexColor(ext.color, theme.accent);
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: badgeColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    ext.ext,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmUninstall(PluginManifest plugin, ThemeConfig theme) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text(
          'Uninstall Plugin',
          style: TextStyle(color: theme.textPrimary),
        ),
        content: Text(
          'Are you sure you want to uninstall "${plugin.name}" (${plugin.id})?',
          style: TextStyle(color: theme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _controller.uninstallPlugin(plugin.id);
            },
            child: const Text('Uninstall'),
          ),
        ],
      ),
    );
  }
}
