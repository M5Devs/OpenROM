// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gui/controllers/plugin_controller.dart';
import 'package:gui/models/theme_config.dart';
import 'package:gui/screens/plugins_screen.dart';
import 'package:gui/services/plugin_service.dart';
import 'package:gui/widgets/orplug_builder_studio.dart';
import 'package:gui/widgets/storefront_view.dart';
import 'package:openrom_core/openrom_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Store rows shaped exactly like `openrom-store.pages.dev/api/plugins.json`.
const _xgdtool = StoreListing(
  id: 'xgdtool_360',
  name: 'Xbox 360 XGDTool Engine',
  version: '1.2.0',
  minCoreVersion: '3.9.0',
  publisherId: 'm5dev',
  publisherName: 'M5 Dev',
  publisherVerified: true,
  category: 'Xbox',
  description: 'Xbox 360 compressed ISO conversion plugin.',
  routes: ['ISO -> ZAR'],
  platforms: ['Windows', 'Linux', 'macOS'],
  downloadUrl: 'https://example.com/xgdtool_360-1.2.0.orplug',
  sha256: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
);

const _ps2 = StoreListing(
  id: 'ps2_gz_compressor',
  name: 'PS2 GZ ISO Tool',
  version: '0.8.2',
  publisherId: 'retrocommunity',
  publisherName: 'RetroCommunity',
  category: 'PlayStation',
  description: 'PS2 ISO gzip tool.',
  routes: ['ISO -> GZ'],
  platforms: ['Windows', 'Linux'],
  downloadUrl: 'https://example.com/ps2_gz_compressor-0.8.2.orplug',
  sha256: 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
);

class FakePluginService extends PluginService {
  final List<PluginManifest> installed;
  final List<StoreListing> listings;
  final bool live;

  FakePluginService({
    this.installed = const [],
    this.live = true,
    this.listings = const [_xgdtool, _ps2],
  });

  @override
  Future<List<PluginManifest>> loadInstalledPlugins() async => installed;

  @override
  Future<({List<StoreListing> listings, String raw})?> fetchLiveStore({
    String? endpointUrl,
  }) async {
    if (!live) return null;
    return (listings: listings, raw: '[{"id":"xgdtool_360"}]');
  }

  @override
  Future<List<StorePlugin>> fetchStoreCatalog({String? endpointUrl}) async =>
      listings.map((l) => l.toStorePlugin()).toList();

  @override
  Future<bool> installPlugin(String orplugPath) async => true;

  @override
  Future<bool> uninstallPlugin(String pluginId) async => true;
}

void main() {
  final testTheme = ThemeConfig.defaultTheme();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PluginController', () {
    test('loadInstalledPlugins updates controller state', () async {
      final fakeManifest = PluginManifest(
        id: 'test_plugin',
        name: 'Test Plugin',
        version: const SemVer(1, 0, 0),
        minCoreVersion: const SemVer(3, 0, 0),
        description: 'A test plugin.',
        publisher: const PluginPublisher(id: 'tester', name: 'Test Author'),
      );

      final controller = PluginController(
          service: FakePluginService(installed: [fakeManifest]));
      await controller.loadInstalledPlugins();

      expect(controller.installedPlugins.length, 1);
      expect(controller.installedPlugins.first.author, 'Test Author');
      expect(controller.isPluginInstalled('test_plugin'), isTrue);
      expect(controller.isPluginInstalled('nope'), isFalse);
    });

    test('fetchLiveStore marks the catalogue live', () async {
      final controller = PluginController(service: FakePluginService());
      await controller.fetchLiveStore();

      expect(controller.storeIsLive, isTrue);
      expect(controller.storeListings.length, 2);
      expect(controller.storeCategories, ['PlayStation', 'Xbox']);
    });

    test('fetchLiveStore falls back to the cache when offline', () async {
      SharedPreferences.setMockInitialValues({
        'openrom_store_cache_v1': '[{"id":"cached_tool","name":"Cached Tool",'
            '"version":"1.0.0","category":"Utility"}]',
      });
      final controller =
          PluginController(service: FakePluginService(live: false));
      await controller.fetchLiveStore();

      expect(controller.storeIsLive, isFalse);
      expect(controller.storeListings.single.id, 'cached_tool');
    });

    test('search filters by name, id, publisher and route', () async {
      final controller = PluginController(service: FakePluginService());
      await controller.fetchLiveStore();

      controller.setStoreQuery('xgd');
      expect(controller.filteredStoreListings.single.id, 'xgdtool_360');

      controller.setStoreQuery('retrocommunity');
      expect(controller.filteredStoreListings.single.id, 'ps2_gz_compressor');

      controller.setStoreQuery('ISO -> GZ');
      expect(controller.filteredStoreListings.single.id, 'ps2_gz_compressor');

      controller.setStoreQuery('');
      expect(controller.filteredStoreListings.length, 2);
    });

    test('category filter narrows the listing set', () async {
      final controller = PluginController(service: FakePluginService());
      await controller.fetchLiveStore();

      controller.setStoreCategory('Xbox');
      expect(controller.filteredStoreListings.single.id, 'xgdtool_360');

      controller.setStoreCategory(null);
      expect(controller.filteredStoreListings.length, 2);
    });
  });

  group('PluginsScreen', () {
    testWidgets('renders the three tabs', (tester) async {
      final controller = PluginController(service: FakePluginService());
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PluginsScreen(theme: testTheme, controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Installed Plugins 📦'), findsOneWidget);
      expect(find.text('Plugin Store 🌐🛒'), findsOneWidget);
      expect(find.text('Create / Studio 🛠️'), findsOneWidget);
      expect(find.text('Drag & Drop .orplug Archive Here'), findsOneWidget);
    });

    testWidgets('storefront shows live listings with a verified badge',
        (tester) async {
      final controller = PluginController(service: FakePluginService());
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PluginsScreen(theme: testTheme, controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Plugin Store 🌐🛒'));
      await tester.pumpAndSettle();

      expect(find.text('Xbox 360 XGDTool Engine'), findsOneWidget);
      expect(find.text('by M5 Dev'), findsOneWidget);
      expect(find.byIcon(Icons.verified), findsOneWidget);
      expect(find.text('PS2 GZ ISO Tool'), findsOneWidget);
      expect(find.text('Live'), findsOneWidget);
    });

    testWidgets('storefront search narrows the visible cards', (tester) async {
      final controller = PluginController(service: FakePluginService());
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PluginsScreen(theme: testTheme, controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Plugin Store 🌐🛒'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(StorefrontKeys.search), 'ps2');
      await tester.pumpAndSettle();

      expect(find.text('PS2 GZ ISO Tool'), findsOneWidget);
      expect(find.text('Xbox 360 XGDTool Engine'), findsNothing);
    });

    testWidgets('storefront shows the offline state with the mascot',
        (tester) async {
      final controller =
          PluginController(service: FakePluginService(live: false));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PluginsScreen(theme: testTheme, controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Plugin Store 🌐🛒'));
      await tester.pumpAndSettle();

      expect(find.text('Offline'), findsOneWidget);
      expect(find.text('ROMéo is offline'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName ==
                'assets/images/romeo-error.png'),
        findsOneWidget,
      );
    });

    testWidgets('studio tab renders the builder form', (tester) async {
      final controller = PluginController(service: FakePluginService());
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PluginsScreen(theme: testTheme, controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create / Studio 🛠️'));
      await tester.pumpAndSettle();

      expect(find.text('Visual .orplug Builder Studio'), findsOneWidget);
      expect(find.byKey(BuilderStudioKeys.idField), findsOneWidget);

      // The Build button lives at the bottom of the form; scroll it into view.
      await tester.dragUntilVisible(
        find.byKey(BuilderStudioKeys.build),
        find.byType(ListView).last,
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(BuilderStudioKeys.build), findsOneWidget);
    });
  });
}
