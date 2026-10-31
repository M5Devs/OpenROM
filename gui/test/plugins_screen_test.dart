// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gui/controllers/plugin_controller.dart';
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
        description: 'Xbox 360 compressed ISO conversion plugin.',
        publisher: StorePublisher(id: 'm5dev', name: 'M5 Dev', verified: true),
        tags: ['.zar', '.cci'],
        channels: {
          'stable': StoreChannel(channel: 'stable', version: '1.2.0'),
        },
      ),
      StorePlugin(
        id: 'ps2_gz_compressor',
        name: 'PS2 GZ ISO Tool',
        description: 'PS2 ISO gzip tool.',
        publisher: StorePublisher(
            id: 'retrocommunity', name: 'RetroCommunity', verified: false),
        tags: ['.gz'],
        channels: {
          'stable': StoreChannel(channel: 'stable', version: '0.8.2'),
        },
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
        version: const SemVer(1, 0, 0),
        minCoreVersion: const SemVer(3, 0, 0),
        description: 'A test plugin.',
        publisher: const PluginPublisher(id: 'tester', name: 'Test Author'),
        extensions: const [
          PluginExtension(
            ext: '.test',
            format: 'TEST',
            platform: 'Test Platform',
            color: '#00e5ff',
          )
        ],
      );

      final service = FakePluginService(installed: [fakeManifest]);
      final controller = PluginController(service: service);

      await controller.loadInstalledPlugins();

      expect(controller.installedPlugins.length, 1);
      expect(controller.installedPlugins.first.name, 'Test Plugin');
      expect(controller.installedPlugins.first.author, 'Test Author');
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
