// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gui/controllers/plugin_controller.dart';
import 'package:gui/models/store_plugin.dart';
import 'package:gui/models/theme_config.dart';
import 'package:gui/screens/plugins_screen.dart';
import 'package:gui/services/plugin_service.dart';
import 'package:openrom_core/openrom_core.dart';

class FakePluginService extends PluginService {
  final List<PluginManifest> installed;
  final List<StorePlugin> catalog;

  FakePluginService({
    this.installed = const [],
    this.catalog = const [
      StorePlugin(
        id: 'xgdtool_360',
        name: 'Xbox 360 XGDTool Engine',
        version: '1.2.0',
        author: 'M5 Dev',
        description: 'Xbox 360 compressed ISO conversion plugin.',
        isVerified: true,
        tags: ['.zar', '.cci'],
      ),
      StorePlugin(
        id: 'ps2_gz_compressor',
        name: 'PS2 GZ ISO Tool',
        version: '0.8.2',
        author: 'RetroCommunity',
        description: 'PS2 ISO gzip tool.',
        isVerified: false,
        tags: ['.gz'],
      ),
    ],
  });

  @override
  Future<List<PluginManifest>> loadInstalledPlugins() async {
    return installed;
  }

  @override
  Future<List<StorePlugin>> fetchStoreCatalog({String? endpointUrl}) async {
    return catalog;
  }

  @override
  Future<bool> installPlugin(String orplugPath) async {
    return true;
  }

  @override
  Future<bool> uninstallPlugin(String pluginId) async {
    return true;
  }
}

void main() {
  final testTheme = ThemeConfig.defaultTheme();

  group('PluginController Unit Tests', () {
    test('loadInstalledPlugins updates controller state', () async {
      final fakeManifest = PluginManifest(
        id: 'test_plugin',
        name: 'Test Plugin',
        version: '1.0.0',
        author: 'Test Author',
        description: 'A test plugin.',
        minCoreVersion: '3.0.0',
        binaries: {},
        extensions: [
          PluginExtension(
            ext: '.test',
            format: 'TEST',
            platform: 'Test Platform',
            color: '#00e5ff',
          )
        ],
        conversions: [],
      );

      final service = FakePluginService(installed: [fakeManifest]);
      final controller = PluginController(service: service);

      await controller.loadInstalledPlugins();

      expect(controller.installedPlugins.length, 1);
      expect(controller.installedPlugins.first.name, 'Test Plugin');
      expect(controller.isPluginInstalled('test_plugin'), isTrue);
      expect(controller.isPluginInstalled('non_existent'), isFalse);
    });

    test('fetchStoreCatalog populates store catalog', () async {
      final service = FakePluginService();
      final controller = PluginController(service: service);

      await controller.fetchStoreCatalog();

      expect(controller.storeCatalog.length, 2);
      expect(controller.storeCatalog.first.isVerified, isTrue);
      expect(controller.storeCatalog.first.author, 'M5 Dev');
    });
  });

  group('PluginsScreen Widget Tests', () {
    testWidgets('Renders tabs and empty state when no plugins are installed',
        (WidgetTester tester) async {
      final service = FakePluginService(installed: []);
      final controller = PluginController(service: service);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PluginsScreen(
              theme: testTheme,
              controller: controller,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Installed Plugins 📦'), findsOneWidget);
      expect(find.text('Plugin Store 🌐🛒'), findsOneWidget);
      expect(find.text('Drag & Drop .orplug Archive Here'), findsOneWidget);
      expect(find.text('Browse .orplug File'), findsOneWidget);
      expect(find.text('No Plugins Installed Yet'), findsOneWidget);
    });

    testWidgets('Switching to Plugin Store displays verified badge for M5 Dev',
        (WidgetTester tester) async {
      final service = FakePluginService(installed: []);
      final controller = PluginController(service: service);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PluginsScreen(
              theme: testTheme,
              controller: controller,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on Plugin Store Tab
      await tester.tap(find.text('Plugin Store 🌐🛒'));
      await tester.pumpAndSettle();

      expect(find.text('Xbox 360 XGDTool Engine'), findsOneWidget);
      expect(find.text('by M5 Dev'), findsOneWidget);
      expect(find.byIcon(Icons.verified), findsOneWidget);
      expect(find.text('PS2 GZ ISO Tool'), findsOneWidget);
    });
  });
}
