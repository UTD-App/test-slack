import 'package:flutter_test/flutter_test.dart';
import 'package:gifts/src/presentation/utils/media.dart';
import 'package:utd_app/config/app_config.dart';

void main() {
  // resolveMediaUrl reads appConfig.domainUrl, so the config must be
  // initialized first. Use a fixed domain for deterministic assertions.
  setUpAll(() {
    if (!AppConfigProvider.isInitialized) {
      AppConfigProvider.initialize(
        const AppConfig(
          appName: 'test',
          baseUrl: 'https://example.test/api',
          storageBucketUrl: 'https://example.test/bucket',
          domainUrl: 'https://example.test',
          privacyPolicyUrl: 'https://example.test/privacy',
          environment: Environment.development,
        ),
      );
    }
  });

  group('gifts resolveMediaUrl', () {
    test('null and empty return empty string', () {
      expect(resolveMediaUrl(null), '');
      expect(resolveMediaUrl(''), '');
    });

    test('absolute http(s) URLs pass through untouched', () {
      expect(resolveMediaUrl('http://cdn.x/a.png'), 'http://cdn.x/a.png');
      expect(resolveMediaUrl('https://cdn.x/a.png'), 'https://cdn.x/a.png');
    });

    test('relative path is served from domain /storage', () {
      expect(
        resolveMediaUrl('gifts/rose.png'),
        '${appConfig.domainUrl}/storage/gifts/rose.png',
      );
    });

    test('leading slash is stripped before joining', () {
      expect(
        resolveMediaUrl('/gifts/rose.png'),
        '${appConfig.domainUrl}/storage/gifts/rose.png',
      );
    });
  });
}
