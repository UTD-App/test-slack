import 'package:flutter_test/flutter_test.dart';
import 'package:utd_app/shared/profile/public_user.dart';

/// Pure-Dart unit tests for [PublicUser.fromJson].
///
/// Covers the nested profile/country/stats envelopes, the name/bio
/// trim-and-fallback logic, num->int coercion, avatar image/avatar precedence,
/// and the is_online / is_me booleans.
void main() {
  group('PublicUser.fromJson', () {
    test('happy path: full envelope with nested profile/country/stats', () {
      final json = <String, dynamic>{
        'id': 42,
        'name': 'Sara',
        'uuid': 12345,
        'bio': '  loves coding  ',
        'is_online': true,
        'is_me': true,
        'profile': <String, dynamic>{
          'image': 'https://cdn/sara.png',
          'gender': 2,
        },
        'country': <String, dynamic>{
          'name': 'Egypt',
          'flag': 'eg.png',
        },
        'stats': <String, dynamic>{
          'friends': 10,
          'following': 5,
          'followers': 7,
        },
      };

      final u = PublicUser.fromJson(json);

      expect(u.id, 42);
      expect(u.name, 'Sara');
      // uuid coerced to string via interpolation.
      expect(u.uuid, '12345');
      // bio trimmed.
      expect(u.bio, 'loves coding');
      expect(u.avatar, 'https://cdn/sara.png');
      expect(u.gender, 2);
      expect(u.countryName, 'Egypt');
      expect(u.countryFlag, 'eg.png');
      expect(u.isOnline, true);
      expect(u.friends, 10);
      expect(u.following, 5);
      expect(u.followers, 7);
      expect(u.isMe, true);
    });

    test('empty json: safe defaults', () {
      final u = PublicUser.fromJson(<String, dynamic>{});

      expect(u.id, 0);
      // missing/blank name falls back to em-dash.
      expect(u.name, '—');
      expect(u.uuid, ''); // '${null ?? ''}'
      expect(u.bio, isNull);
      expect(u.avatar, isNull);
      expect(u.gender, isNull);
      expect(u.countryName, isNull);
      expect(u.countryFlag, isNull);
      expect(u.isOnline, false);
      expect(u.friends, 0);
      expect(u.following, 0);
      expect(u.followers, 0);
      expect(u.isMe, false);
    });

    test('blank / whitespace name falls back to em-dash', () {
      expect(PublicUser.fromJson({'name': ''}).name, '—');
      expect(PublicUser.fromJson({'name': '   '}).name, '—');
      // non-blank kept as-is (not trimmed for name).
      expect(PublicUser.fromJson({'name': ' Bob '}).name, ' Bob ');
    });

    test('blank bio -> null; whitespace bio -> null', () {
      expect(PublicUser.fromJson({'bio': ''}).bio, isNull);
      expect(PublicUser.fromJson({'bio': '   '}).bio, isNull);
      expect(PublicUser.fromJson({'bio': ' x '}).bio, 'x');
    });

    test('avatar prefers profile.image, falls back to profile.avatar', () {
      final withImage = PublicUser.fromJson({
        'profile': {'image': 'img.png', 'avatar': 'av.png'},
      });
      expect(withImage.avatar, 'img.png');

      final onlyAvatar = PublicUser.fromJson({
        'profile': {'avatar': 'av.png'},
      });
      expect(onlyAvatar.avatar, 'av.png');

      final neither = PublicUser.fromJson({'profile': {}});
      expect(neither.avatar, isNull);
    });

    test('id and stats accept num (double) and coerce to int', () {
      final u = PublicUser.fromJson({
        'id': 9.0,
        'profile': {'gender': 1.0},
        'stats': {'friends': 3.0, 'following': 2.9, 'followers': 1.0},
      });

      expect(u.id, 9);
      expect(u.gender, 1);
      expect(u.friends, 3);
      expect(u.following, 2); // truncated by toInt()
      expect(u.followers, 1);
    });

    test('non-map profile/country/stats are ignored safely', () {
      final u = PublicUser.fromJson({
        'profile': 'not-a-map',
        'country': 42,
        'stats': <dynamic>[],
      });

      expect(u.avatar, isNull);
      expect(u.gender, isNull);
      expect(u.countryName, isNull);
      expect(u.friends, 0);
    });

    test('is_online only true for the literal boolean true', () {
      expect(PublicUser.fromJson({'is_online': true}).isOnline, true);
      expect(PublicUser.fromJson({'is_online': 1}).isOnline, false);
      expect(PublicUser.fromJson({'is_online': 'true'}).isOnline, false);
      expect(PublicUser.fromJson({'is_online': false}).isOnline, false);
    });

    test('dynamic-keyed nested maps (cache shape) are cast safely', () {
      final json = <String, dynamic>{
        'id': 1,
        'profile': <dynamic, dynamic>{'image': 'c.png', 'gender': 2},
        'stats': <dynamic, dynamic>{'friends': 4},
      };

      final u = PublicUser.fromJson(json);

      expect(u.avatar, 'c.png');
      expect(u.gender, 2);
      expect(u.friends, 4);
    });
  });
}
