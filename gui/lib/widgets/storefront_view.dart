// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'package:flutter/material.dart';
import 'package:openrom_core/openrom_core.dart';

import '../controllers/plugin_controller.dart';
import '../models/theme_config.dart';

/// Keys used by widget tests to drive the storefront.
abstract final class StorefrontKeys {
  static const search = Key('storefront.search');
  static const refresh = Key('storefront.refresh');
  static Key category(String c) => Key('storefront.category.$c');
  static Key install(String id) => Key('storefront.install.$id');
}

/// The live in-app marketplace storefront.
///
/// Consumes `https://openrom-store.pages.dev/api/plugins.json`, falling back to
/// the last cached catalogue when offline. Filters client-side by category and
/// free-text search, and installs through the verified download path.
class StorefrontView extends StatefulWidget {
  final ThemeConfig theme;
  final PluginController controller;

  const StorefrontView({
    super.key,
    required this.theme,
    required this.controller,
  });

  @override
  State<StorefrontView> createState() => _StorefrontViewState();
}

class _StorefrontViewState extends State<StorefrontView> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final controller = widget.controller;
    final listings = controller.filteredStoreListings;
    final categories = controller.storeCategories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.storefront, color: theme.accent, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Plugin Marketplace',
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _liveBadge(theme, controller),
                  const Spacer(),
                  IconButton(
                    key: StorefrontKeys.refresh,
                    tooltip: 'Refresh catalogue',
                    onPressed: controller.isLoading
                        ? null
                        : () => controller.fetchLiveStore(force: true),
                    icon: Icon(Icons.refresh, color: theme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                controller.storeIsLive
                    ? 'Official and community plugins, served live from the store.'
                    : 'Showing the last cached catalogue. Reconnect to refresh.',
                style: TextStyle(color: theme.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 12),
              _searchField(theme, controller),
              const SizedBox(height: 10),
              if (categories.isNotEmpty)
                _categoryChips(theme, controller, categories),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _body(theme, controller, listings),
        ),
      ],
    );
  }

  Widget _liveBadge(ThemeConfig theme, PluginController controller) {
    if (!controller.storeFetchAttempted) return const SizedBox.shrink();
    final live = controller.storeIsLive;
    final color = live ? theme.accent : Colors.orangeAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(live ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
              size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            live ? 'Live' : 'Offline',
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _searchField(ThemeConfig theme, PluginController controller) {
    return TextField(
      key: StorefrontKeys.search,
      controller: _searchCtrl,
      style: TextStyle(color: theme.textPrimary, fontSize: 14),
      onChanged: controller.setStoreQuery,
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Search plugins, publishers, routes…',
        hintStyle: TextStyle(
            color: theme.textSecondary.withValues(alpha: 0.6), fontSize: 13),
        prefixIcon: Icon(Icons.search, size: 18, color: theme.textSecondary),
        suffixIcon: _searchCtrl.text.isEmpty
            ? null
            : IconButton(
                icon: Icon(Icons.close, size: 16, color: theme.textSecondary),
                onPressed: () {
                  _searchCtrl.clear();
                  controller.setStoreQuery('');
                  setState(() {});
                },
              ),
        filled: true,
        fillColor: theme.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _categoryChips(
    ThemeConfig theme,
    PluginController controller,
    List<String> categories,
  ) {
    final selected = controller.storeCategory;
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        _chip(theme, 'All', selected == null, () {
          controller.setStoreCategory(null);
        }, key: StorefrontKeys.category('all')),
        ...categories.map((c) {
          return _chip(theme, c, selected == c, () {
            controller.setStoreCategory(selected == c ? null : c);
          }, key: StorefrontKeys.category(c));
        }),
      ],
    );
  }

  Widget _chip(
    ThemeConfig theme,
    String label,
    bool active,
    VoidCallback onTap, {
    Key? key,
  }) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? theme.accent : theme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? theme.accent : theme.cardBg,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.black : theme.textSecondary,
            fontSize: 12,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _body(
    ThemeConfig theme,
    PluginController controller,
    List<StoreListing> listings,
  ) {
    if (controller.isLoading && listings.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: theme.accent),
      );
    }

    if (listings.isEmpty) {
      return _emptyState(theme, controller);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: listings.length,
      itemBuilder: (context, i) => _listingCard(theme, controller, listings[i]),
    );
  }

  Widget _emptyState(ThemeConfig theme, PluginController controller) {
    final offline = controller.storeFetchAttempted && !controller.storeIsLive;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              offline
                  ? 'assets/images/romeo-error.png'
                  : 'assets/images/romeo.png',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 16),
            Text(
              offline
                  ? 'ROMéo is offline'
                  : controller.storeQuery.isEmpty
                      ? 'No plugins published yet'
                      : 'No plugins match your filters',
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              offline
                  ? 'The store could not be reached and no cached copy exists. '
                      'Check your connection and refresh.'
                  : controller.storeQuery.isEmpty
                      ? 'Check back soon — new plugins land often.'
                      : 'Try a different search term or category.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _listingCard(
    ThemeConfig theme,
    PluginController controller,
    StoreListing listing,
  ) {
    final installed = controller.isPluginInstalled(listing.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.cardBg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    Icon(_iconFor(listing.icon), color: theme.accent, size: 22),
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
                            listing.name,
                            style: TextStyle(
                              color: theme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _pill(theme, 'v${listing.version}'),
                        const SizedBox(width: 6),
                        _pill(theme, listing.category),
                        if (listing.publisherVerified) ...[
                          const SizedBox(width: 6),
                          const Tooltip(
                            message: 'Verified publisher',
                            child: Icon(Icons.verified,
                                color: Color(0xFF00E5FF), size: 16),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'by ${listing.publisherName}',
                      style:
                          TextStyle(color: theme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (listing.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              listing.description,
              style: TextStyle(color: theme.textSecondary, fontSize: 13),
            ),
          ],
          if (listing.routes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: listing.routes
                  .map((r) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.cardBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          r,
                          style: TextStyle(
                              color: theme.textSecondary, fontSize: 11),
                        ),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (listing.platforms.isNotEmpty)
                Icon(Icons.devices, size: 14, color: theme.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  listing.platforms.join(' · '),
                  style: TextStyle(color: theme.textSecondary, fontSize: 11),
                ),
              ),
              if (listing.minCoreVersion != null &&
                  listing.minCoreVersion!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    'core ≥ ${listing.minCoreVersion}',
                    style: TextStyle(color: theme.textSecondary, fontSize: 11),
                  ),
                ),
              if (installed)
                Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: theme.accent),
                    const SizedBox(width: 6),
                    Text('Installed',
                        style: TextStyle(color: theme.accent, fontSize: 12)),
                  ],
                )
              else
                ElevatedButton.icon(
                  key: StorefrontKeys.install(listing.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.accent,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(110, 38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: controller.isLoading
                      ? null
                      : () => _install(controller, listing),
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Install',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(ThemeConfig theme, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: theme.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _install(
    PluginController controller,
    StoreListing listing,
  ) async {
    final ok = await controller.installListing(listing);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (ok) {
      messenger.showSnackBar(
        SnackBar(content: Text('${listing.name} installed')),
      );
    } else if (controller.errorMessage != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(controller.errorMessage!)),
      );
    }
  }

  static IconData _iconFor(String name) {
    switch (name) {
      case 'gamepad':
        return Icons.sports_esports;
      case 'disc':
        return Icons.album;
      case 'build':
        return Icons.build;
      case 'patch':
        return Icons.healing;
      case 'storage':
        return Icons.storage;
      default:
        return Icons.extension;
    }
  }
}
