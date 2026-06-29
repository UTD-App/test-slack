import 'package:flutter_test/flutter_test.dart';
import 'package:moment/src/presentation/utils/media.dart';
import 'package:utd_app/config/app_config.dart';

void main() {
  // resolveMediaUrl/avatarUrl read appConfig.domainUrl for relative paths.
  setUpAll(() {
    if (!AppConfigProvider.isInitialized) {
      AppConfigProvider.initialize(
        AppConfig.development().copyWith(domainUrl: 'https://example.test'),
      );
    }
  });

  group('resolveMediaUrl', () {
    test('empty path returns empty string', () {
      expect(resolveMediaUrl(''), '');
    });

    test('absolute http(s) URLs pass through unchanged', () {
      expect(
        resolveMediaUrl('http://cdn.x/a.jpg'),
        'http://cdn.x/a.jpg',
      );
      expect(
        resolveMediaUrl('https://cdn.x/a.jpg'),
        'https://cdn.x/a.jpg',
      );
    });

    test('relative path is served from the app domain under /storage', () {
      expect(
        resolveMediaUrl('posts/a.jpg'),
        'https://example.test/storage/posts/a.jpg',
      );
    });

    test('leading slash is stripped before joining', () {
      expect(
        resolveMediaUrl('/posts/a.jpg'),
        'https://example.test/storage/posts/a.jpg',
      );
    });
  });

  group('avatarUrl', () {
    test('absolute http image passes through', () {
      expect(
        avatarUrl('https://cdn.x/me.png', 'Ada'),
        'https://cdn.x/me.png',
      );
    });

    test('relative image resolves via storage', () {
      expect(
        avatarUrl('avatars/me.png', 'Ada'),
        'https://example.test/storage/avatars/me.png',
      );
    });

    test('empty image => ui-avatars fallback with encoded name', () {
      expect(
        avatarUrl('', 'Ada Lovelace'),
        'https://ui-avatars.com/api/?name=Ada%20Lovelace&background=4f46e5&color=fff',
      );
    });

    test('blank name falls back to "User"', () {
      expect(
        avatarUrl('', '   '),
        'https://ui-avatars.com/api/?name=User&background=4f46e5&color=fff',
      );
    });
  });
}
