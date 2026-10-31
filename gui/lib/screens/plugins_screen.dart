// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:openrom_core/openrom_core.dart';

import '../controllers/plugin_controller.dart';
import '../models/theme_config.dart';

class PluginsScreen extends StatefulWidget {
  final ThemeConfig theme;
  final PluginController? controller;

  const PluginsScreen({
    super.key,
    required this.theme,
    this.controller,
  });

  @override
  State<PluginsScreen> createState() => _PluginsScreenState();
}

class _PluginsScreenState extends State<PluginsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final PluginController _controller;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _controller = widget.controller ?? PluginController();
    _controller.addListener(_onControllerChanged);
    _controller.loadInstalledPlugins();
    _controller.fetchStoreCatalog();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.removeListener(_onControllerChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
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
              _buildStoreTab(theme),
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

  Widget _buildStoreTab(ThemeConfig theme) {
    final storeCatalog = _controller.storeCatalog;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Icon(
              Icons.explore,
              color: theme.accent,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Community & Official Plugins',
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Discover plugins created by official developers and the retro community.',
          style: TextStyle(
            color: theme.textSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),
        ...storeCatalog.map(
          (item) => _buildStoreCard(item, theme),
        ),
      ],
    );
  }

  Widget _buildStoreCard(StorePlugin storeItem, ThemeConfig theme) {
    final isInstalled = _controller.isPluginInstalled(storeItem.id);

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            storeItem.name,
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
                            'v${storeItem.version}',
                            style: TextStyle(
                              color: theme.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'by ${storeItem.author}',
                          style: TextStyle(
                            color: theme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        if (storeItem.isVerified ||
                            storeItem.author == 'M5 Dev') ...[
                          const SizedBox(width: 4),
                          Tooltip(
                            message: 'Verified Publisher 💙',
                            child: Icon(
                              Icons.verified,
                              color: const Color(0xFF00E5FF),
                              size: 16,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (isInstalled)
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.accent.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: theme.accent,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Installed',
                        style: TextStyle(
                          color: theme.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.accent,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(110, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _controller.installFromStore(storeItem),
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text(
                    'Install',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            storeItem.description,
            style: TextStyle(
              color: theme.textPrimary.withValues(alpha: 0.9),
              fontSize: 13,
            ),
          ),
          if (storeItem.tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: storeItem.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: theme.cardBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: theme.textSecondary,
                      fontSize: 11,
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
}
