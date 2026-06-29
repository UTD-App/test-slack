import 'package:flutter_test/flutter_test.dart';
import 'package:profile/src/presentation/utils/media.dart';
import 'package:utd_app/config/app_config.dart';

void main() {
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

  group('profile resolveMediaUrl', () {
    test('null and empty return empty string', () {
      expect(resolveMediaUrl(null), '');
      expect(resolveMediaUrl(''), '');
    });

    test('absolute http(s) URLs pass through', () {
      expect(resolveMediaUrl('https://i.pravatar.cc/1'),
          'https://i.pravatar.cc/1');
      expect(resolveMediaUrl('http://x/y'), 'http://x/y');
    });

    test('relative path served from domain /storage', () {
      expect(resolveMediaUrl('avatars/a.jpg'),
          '${appConfig.domainUrl}/storage/avatars/a.jpg');
    });

    test('leading slash stripped', () {
      expect(resolveMediaUrl('/avatars/a.jpg'),
          '${appConfig.domainUrl}/storage/avatars/a.jpg');
    });
  });

  group('avatarUrl', () {
    test('resolves an existing image path through resolveMediaUrl', () {
      expect(avatarUrl('avatars/a.jpg', 'Bob'),
          '${appConfig.domainUrl}/storage/avatars/a.jpg');
    });

    test('absolute image passes through', () {
      expect(avatarUrl('https://cdn/a.png', 'Bob'), 'https://cdn/a.png');
    });

    test('falls back to ui-avatars with cleaned name when image empty', () {
      final url = avatarUrl(null, 'Alice');
      expect(url, startsWith('https://ui-avatars.com/api/?name='));
      expect(url, contains('name=Alice'));
    });

    test('strips emoji/punctuation from the generated name', () {
      final url = avatarUrl('', 'mekooo😚');
      // emoji removed -> name should be just "mekooo"
      expect(url, contains('name=mekooo'));
      expect(url, isNot(contains('😚')));
    });

    test('falls back to "User" when name has no usable characters', () {
      final url = avatarUrl(null, '😚😚😚');
      expect(url, contains('name=User'));
    });

    test('null name falls back to "User"', () {
      final url = avatarUrl(null, null);
      expect(url, contains('name=User'));
    });

    test('keeps Arabic letters in the generated name', () {
      final url = avatarUrl('', 'علي');
      // URL-encoded Arabic, but must not collapse to "User".
      expect(url, isNot(contains('name=User')));
    });
  });
}
