// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gui/controllers/plugin_controller.dart';
import 'package:gui/models/theme_config.dart';
import 'package:gui/screens/plugins_screen.dart';
import 'package:gui/services/deeplink_service.dart';
import 'package:gui/services/plugin_service.dart';
import 'package:gui/widgets/deep_link_dialog.dart';
import 'package:openrom_core/openrom_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class FakePluginService extends PluginService {
  int installCalls = 0;
  StoreListing? lastInstalled;

  @override
  Future<List<PluginManifest>> loadInstalledPlugins() async => const [];

  @override
  Future<({List<StoreListing> listings, String raw})?> fetchLiveStore({
    String? endpointUrl,
  }) async =>
      (listings: const [_xgdtool], raw: '[]');

  @override
  Future<StoreInstallOutcome> installFromListing(StoreListing listing) async {
    installCalls++;
    lastInstalled = listing;
    return const StoreInstallOutcome.success();
  }
}

void main() {
  final testTheme = ThemeConfig.defaultTheme();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('DeepLinkDialog', () {
    testWidgets('shows the listing details and confirms', (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await showDeepLinkInstallDialog(
                    context: ctx,
                    theme: testTheme,
                    listing: _xgdtool,
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Install plugin from link?'), findsOneWidget);
      expect(find.text('Xbox 360 XGDTool Engine'), findsOneWidget);
      expect(find.text('xgdtool_360'), findsOneWidget);
      expect(find.text('M5 Dev'), findsOneWidget);

      await tester.tap(find.byKey(DeepLinkDialogKeys.install));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });

    testWidgets('cancelling returns false', (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await showDeepLinkInstallDialog(
                    context: ctx,
                    theme: testTheme,
                    listing: _xgdtool,
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(DeepLinkDialogKeys.cancel));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });
  });

  group('PluginsScreen deep links', () {
    testWidgets('an install link opens a confirmation and installs',
        (tester) async {
      final service = FakePluginService();
      final controller = PluginController(service: service);
      final links = DeepLinkService();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PluginsScreen(
              theme: testTheme,
              controller: controller,
              deepLinkService: links,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await links.handleRaw('openrom://install/xgdtool_360');
      await tester.pumpAndSettle();

      expect(find.text('Install plugin from link?'), findsOneWidget);
      await tester.tap(find.byKey(DeepLinkDialogKeys.install));
      await tester.pumpAndSettle();

      expect(service.installCalls, 1);
      expect(service.lastInstalled?.id, 'xgdtool_360');

      links.dispose();
    });

    testWidgets('an unknown id shows the not-found dialog', (tester) async {
      final controller = PluginController(service: FakePluginService());
      final links = DeepLinkService();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PluginsScreen(
              theme: testTheme,
              controller: controller,
              deepLinkService: links,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await links.handleRaw('openrom://install/does-not-exist');
      await tester.pumpAndSettle();

      expect(find.text('Plugin not found'), findsOneWidget);
      expect(find.textContaining('does-not-exist'), findsOneWidget);

      links.dispose();
    });

    testWidgets('a malformed link is ignored', (tester) async {
      final service = FakePluginService();
      final controller = PluginController(service: service);
      final links = DeepLinkService();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PluginsScreen(
              theme: testTheme,
              controller: controller,
              deepLinkService: links,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await links.handleRaw('not-a-deeplink');
      await tester.pumpAndSettle();

      expect(find.text('Install plugin from link?'), findsNothing);
      expect(service.installCalls, 0);

      links.dispose();
    });
  });
}
