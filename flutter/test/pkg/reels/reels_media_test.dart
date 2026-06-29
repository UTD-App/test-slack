import 'package:flutter_test/flutter_test.dart';
import 'package:reels/src/presentation/utils/media.dart';
import 'package:utd_app/config/app_config.dart';

void main() {
  setUpAll(() {
    if (!AppConfigProvider.isInitialized) {
      AppConfigProvider.initialize(
        AppConfig.development().copyWith(domainUrl: 'https://example.test'),
      );
    }
  });

  group('resolveMediaUrl', () {
    test('empty => empty', () => expect(resolveMediaUrl(''), ''));

    test('absolute URLs pass through', () {
      expect(resolveMediaUrl('https://x/v.mp4'), 'https://x/v.mp4');
      expect(resolveMediaUrl('http://x/v.mp4'), 'http://x/v.mp4');
    });

    test('relative resolves under /storage', () {
      expect(
        resolveMediaUrl('reels/v.mp4'),
        'https://example.test/storage/reels/v.mp4',
      );
    });

    test('leading slash stripped', () {
      expect(
        resolveMediaUrl('/reels/v.mp4'),
        'https://example.test/storage/reels/v.mp4',
      );
    });
  });

  group('avatarUrl', () {
    test('absolute passes through', () {
      expect(avatarUrl('https://x/me.png', 'A'), 'https://x/me.png');
    });
    test('relative resolves', () {
      expect(
        avatarUrl('a/me.png', 'A'),
        'https://example.test/storage/a/me.png',
      );
    });
    test('empty image => ui-avatars fallback', () {
      expect(
        avatarUrl('', 'Grace H'),
        'https://ui-avatars.com/api/?name=Grace%20H&background=4f46e5&color=fff',
      );
    });
    test('blank name => User', () {
      expect(
        avatarUrl('', ''),
        'https://ui-avatars.com/api/?name=User&background=4f46e5&color=fff',
      );
    });
  });
}
