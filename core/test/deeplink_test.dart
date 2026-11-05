// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'package:openrom_core/openrom_core.dart';
import 'package:test/test.dart';

void main() {
  group('DeepLink.parse', () {
    test('parses the plugin form', () {
      final t = DeepLink.parse('openrom://plugin/nkit')!;
      expect(t.action, DeepLinkAction.plugin);
      expect(t.id, 'nkit');
      expect(t.raw, 'openrom://plugin/nkit');
    });

    test('parses the install form', () {
      final t = DeepLink.parse('openrom://install/nkit')!;
      expect(t.action, DeepLinkAction.install);
      expect(t.id, 'nkit');
    });

    test('accepts the authority-less form', () {
      final t = DeepLink.parse('openrom:install/nkit')!;
      expect(t.action, DeepLinkAction.install);
      expect(t.id, 'nkit');
    });

    test('accepts a query-parameter id', () {
      final t = DeepLink.parse('openrom://plugin?id=nkit')!;
      expect(t.action, DeepLinkAction.plugin);
      expect(t.id, 'nkit');
    });

    test('accepts ids with underscores, dashes and digits', () {
      expect(DeepLink.parse('openrom://install/ps2_gz_compressor')!.id,
          'ps2_gz_compressor');
      expect(
          DeepLink.parse('openrom://install/xgdtool-360')!.id, 'xgdtool-360');
      expect(DeepLink.parse('openrom://install/nkit2')!.id, 'nkit2');
    });

    test('is case-insensitive for scheme and action', () {
      final t = DeepLink.parse('OpenROM://INSTALL/NKit');
      expect(t, isNull, reason: 'ids are lower-case by schema');
      final t2 = DeepLink.parse('OPENROM://Install/nkit')!;
      expect(t2.action, DeepLinkAction.install);
      expect(t2.id, 'nkit');
    });

    test('tolerates surrounding whitespace and quotes', () {
      expect(DeepLink.parse('  openrom://install/nkit  ')!.id, 'nkit');
      expect(DeepLink.fromArguments(['"openrom://install/nkit"'])!.id, 'nkit');
    });

    test('ignores trailing slashes and extra segments', () {
      expect(DeepLink.parse('openrom://install/nkit/')!.id, 'nkit');
      expect(DeepLink.parse('openrom://install/nkit/extra')!.id, 'nkit');
    });

    test('rejects malformed links', () {
      for (final bad in const [
        '',
        '   ',
        'openrom://',
        'openrom://plugin',
        'openrom://plugin/',
        'openrom://unknown/nkit',
        'openrom://install/NKit',
        'openrom://install/has space',
        'openrom://install/../etc/passwd',
        'openrom://install/%2e%2e',
        'https://example.com/install/nkit',
        'not a url',
      ]) {
        expect(DeepLink.parse(bad), isNull, reason: 'should reject: $bad');
      }
    });

    test('keeps the id and ignores query strings and fragments', () {
      expect(DeepLink.parse('openrom://install/nkit?ref=web')!.id, 'nkit');
      expect(DeepLink.parse('openrom://install/nkit#top')!.id, 'nkit');
    });

    test('fromArguments returns the first parseable link', () {
      final t = DeepLink.fromArguments([
        '--some-flag',
        'openrom://install/nkit',
        'openrom://install/other',
      ])!;
      expect(t.id, 'nkit');
    });

    test('fromArguments returns null when no link is present', () {
      expect(DeepLink.fromArguments(['--help', 'file.iso']), isNull);
      expect(DeepLink.fromArguments(const []), isNull);
    });

    test('toJson round-trips the target', () {
      final t = DeepLink.parse('openrom://install/nkit')!;
      expect(t.toJson(), {'action': 'install', 'id': 'nkit'});
    });
  });

  group('StoreListing', () {
    // A verbatim row from https://openrom-store.pages.dev/api/plugins.json
    final liveRow = <String, dynamic>{
      'id': 'nkit',
      'name': 'NKit',
      'version': '3.2.0',
      'minCoreVersion': '3.9.0',
      'publisherId': 'm5dev',
      'publisherName': 'M5 Dev',
      'publisherVerified': false,
      'category': 'Nintendo',
      'description': 'Nintendo GameCube, Wii, and Wii U disc restoration.',
      'routes': ['ISO -> WUA', 'RVZ -> ISO'],
      'platforms': ['Windows', 'Linux', 'macOS'],
      'downloadUrl':
          'https://downloads.sourceforge.net/project/openrom-plugins/m5dev/'
              'nkit/3.2.0/nkit-3.2.0.orplug',
      'sha256':
          'bd62db8e7ab61075e08424f5fe22ed0bdc2d73f9bf3ba5a11cd7ef7af2e8f717',
      'icon': 'gamepad',
      'downloads': 2,
      'createdAt': '2026-11-04 13:18:55',
    };

    test('parses a live catalogue row', () {
      final listing = StoreListing.fromJson(liveRow);
      expect(listing.id, 'nkit');
      expect(listing.name, 'NKit');
      expect(listing.version, '3.2.0');
      expect(listing.minCoreVersion, '3.9.0');
      expect(listing.publisherName, 'M5 Dev');
      expect(listing.category, 'Nintendo');
      expect(listing.routes, ['ISO -> WUA', 'RVZ -> ISO']);
      expect(listing.platforms, ['Windows', 'Linux', 'macOS']);
      expect(listing.downloads, 2);
      expect(listing.icon, 'gamepad');
    });

    test('listFromJson decodes the top-level array', () {
      final list = StoreListing.listFromJson([liveRow, liveRow]);
      expect(list.length, 2);
      expect(list.first.id, 'nkit');
    });

    test('listFromJson tolerates a {plugins:[...]} wrapper and junk', () {
      expect(
          StoreListing.listFromJson({
            'plugins': [liveRow]
          }).length,
          1);
      expect(StoreListing.listFromJson('nonsense'), isEmpty);
      expect(StoreListing.listFromJson([1, 2, liveRow]).length, 1);
    });

    test('falls back to the publisher id when no name is given', () {
      final listing = StoreListing.fromJson(
        {...liveRow, 'publisherName': ''},
      );
      expect(listing.publisherName, 'm5dev');
    });

    test('accepts the snake_case download_url alias', () {
      final row = {...liveRow}
        ..remove('downloadUrl')
        ..['download_url'] = 'https://example.com/x.orplug';
      expect(StoreListing.fromJson(row).downloadUrl,
          'https://example.com/x.orplug');
    });

    test('adapts to a StorePlugin with a verifiable artifact', () {
      final plugin = StoreListing.fromJson(liveRow).toStorePlugin();
      expect(plugin.id, 'nkit');
      expect(plugin.author, 'M5 Dev');
      expect(plugin.version, '3.2.0');

      final channel = plugin.channel('stable')!;
      expect(channel.minCoreVersion, '3.9.0');
      expect(channel.artifactFor('linux_x64'), isNotNull);
      expect(channel.artifactFor('windows_x64'), isNotNull);
      expect(channel.artifactFor('macos_arm64'), isNotNull);
      expect(channel.artifactFor('linux_x64')!.isWellFormed, isTrue);
      expect(channel.artifactFor('linux_x64')!.sha256, liveRow['sha256']);
    });

    test('toJson round-trips', () {
      final listing = StoreListing.fromJson(liveRow);
      final again = StoreListing.fromJson(listing.toJson());
      expect(again.id, listing.id);
      expect(again.downloadUrl, listing.downloadUrl);
      expect(again.routes, listing.routes);
      expect(again.downloads, listing.downloads);
    });

    test('the category list matches the storefront', () {
      expect(kStoreCategories,
          ['Nintendo', 'Sega', 'PlayStation', 'Xbox', 'Utility', 'Patchers']);
    });
  });
}
