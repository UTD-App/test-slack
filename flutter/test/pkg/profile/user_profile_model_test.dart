import 'package:flutter_test/flutter_test.dart';
import 'package:profile/src/domain/user_profile_entity.dart';
import 'package:profile/src/domain/user_profile_model.dart';

void main() {
  group('UserProfileModel.fromJson — core fields', () {
    test('parses a full payload with nested country & profile', () {
      final m = UserProfileModel.fromJson(const {
        'id': 42,
        'uuid': 'UID-42',
        'name': 'Alice',
        'bio': 'hello',
        'online_time': '5m ago',
        'is_me': true,
        'country': {'name': 'Egypt', 'flag': 'eg.png'},
        'profile': {
          'image': 'https://cdn/avatar.png',
          'gender': 1,
          'birthday': '2000-01-01',
          'cover_images': ['https://cdn/c1.png', 'https://cdn/c2.png'],
          'covers': ['raw/c1.png', 'raw/c2.png'],
        },
      });

      expect(m.id, 42);
      expect(m.uuid, 'UID-42');
      expect(m.name, 'Alice');
      expect(m.bio, 'hello');
      expect(m.onlineTime, '5m ago');
      expect(m.isMe, isTrue);
      expect(m.countryName, 'Egypt');
      expect(m.countryFlag, 'eg.png');
      expect(m.avatar, 'https://cdn/avatar.png');
      expect(m.gender, 1);
      expect(m.birthday, '2000-01-01');
      expect(m.covers, ['https://cdn/c1.png', 'https://cdn/c2.png']);
      expect(m.coverPaths, ['raw/c1.png', 'raw/c2.png']);
      expect(m, isA<UserProfileEntity>());
    });

    test('defaults for an empty payload', () {
      final m = UserProfileModel.fromJson(const {});
      expect(m.id, 0);
      expect(m.uuid, isNull);
      expect(m.name, isNull);
      expect(m.bio, isNull);
      expect(m.avatar, isNull);
      expect(m.covers, isEmpty);
      expect(m.coverPaths, isEmpty);
      expect(m.countryName, isNull);
      expect(m.countryFlag, isNull);
      expect(m.gender, isNull);
      expect(m.birthday, isNull);
      expect(m.onlineTime, isNull);
      expect(m.isMe, isFalse);
      expect(m.extensions, isEmpty);
    });

    test('avatar falls back to profile.avatar when image absent', () {
      final m = UserProfileModel.fromJson(const {
        'id': 1,
        'profile': {'avatar': 'raw/avatar.png'},
      });
      expect(m.avatar, 'raw/avatar.png');
    });

    test('avatar prefers image over avatar', () {
      final m = UserProfileModel.fromJson(const {
        'id': 1,
        'profile': {'image': 'IMG', 'avatar': 'RAW'},
      });
      expect(m.avatar, 'IMG');
    });

    test('covers fall back to raw covers when cover_images absent', () {
      final m = UserProfileModel.fromJson(const {
        'id': 1,
        'profile': {
          'covers': ['raw/c1.png', 'raw/c2.png'],
        },
      });
      expect(m.covers, ['raw/c1.png', 'raw/c2.png']);
      expect(m.coverPaths, ['raw/c1.png', 'raw/c2.png']);
    });

    test('covers coercion drops null/empty entries and stringifies', () {
      final m = UserProfileModel.fromJson(const {
        'id': 1,
        'profile': {
          'cover_images': ['a.png', null, '', 'b.png', 5],
        },
      });
      expect(m.covers, ['a.png', 'b.png', '5']);
    });

    test('non-list cover value yields empty list', () {
      final m = UserProfileModel.fromJson(const {
        'id': 1,
        'profile': {'cover_images': 'not-a-list'},
      });
      expect(m.covers, isEmpty);
    });
  });

  group('UserProfileModel.fromJson — extensions', () {
    test('captures non-core keys into extensions', () {
      final m = UserProfileModel.fromJson(const {
        'id': 1,
        'name': 'X',
        'wealth_level': 7, // unknown key -> ext
        'badges': ['vip', 'star'],
        'email': 'hidden@x.com', // known key -> excluded
        'roles': ['admin'], // known key -> excluded
      });
      expect(m.extensions.containsKey('wealth_level'), isTrue);
      expect(m.extensions.containsKey('badges'), isTrue);
      expect(m.extensions.containsKey('email'), isFalse);
      expect(m.extensions.containsKey('roles'), isFalse);
      // core keys also excluded
      expect(m.extensions.containsKey('id'), isFalse);
      expect(m.extensions.containsKey('name'), isFalse);
    });
  });

  group('UserProfileModel computed getters', () {
    test('wealthLevel / charmLevel from direct ext keys', () {
      final m = UserProfileModel.fromJson(const {
        'id': 1,
        'wealth_level': 9,
        'charm_level': 4,
      });
      expect(m.wealthLevel, 9);
      expect(m.charmLevel, 4);
    });

    test('wealth/charm fall back to gifts.sender_level/receiver_level', () {
      final m = UserProfileModel.fromJson(const {
        'id': 1,
        'gifts': {'sender_level': 3, 'receiver_level': 6},
      });
      expect(m.wealthLevel, 3);
      expect(m.charmLevel, 6);
    });

    test('direct ext keys win over gifts fallback', () {
      final m = UserProfileModel.fromJson(const {
        'id': 1,
        'wealth_level': 1,
        'gifts': {'sender_level': 99},
      });
      expect(m.wealthLevel, 1);
    });

    test('wealth/charm null when neither present', () {
      final m = UserProfileModel.fromJson(const {'id': 1});
      expect(m.wealthLevel, isNull);
      expect(m.charmLevel, isNull);
    });

    test('_asInt coerces numeric string and num for levels', () {
      final m = UserProfileModel.fromJson(const {
        'id': 1,
        'wealth_level': '8',
        'charm_level': 4.0,
      });
      expect(m.wealthLevel, 8);
      expect(m.charmLevel, 4);
    });

    test('avatarFrame from frame/avatar_frame ext, null when empty', () {
      expect(
        UserProfileModel.fromJson(const {'id': 1, 'avatar_frame': 'f.png'})
            .avatarFrame,
        'f.png',
      );
      expect(
        UserProfileModel.fromJson(const {'id': 1, 'frame': 'g.png'}).avatarFrame,
        'g.png',
      );
      expect(
        UserProfileModel.fromJson(const {'id': 1, 'avatar_frame': ''})
            .avatarFrame,
        isNull,
      );
      expect(UserProfileModel.fromJson(const {'id': 1}).avatarFrame, isNull);
    });

    test('badges parsed from ext list, stringified', () {
      final m = UserProfileModel.fromJson(const {
        'id': 1,
        'badges': ['vip', 7],
      });
      expect(m.badges, ['vip', '7']);
    });

    test('badges empty when absent', () {
      expect(UserProfileModel.fromJson(const {'id': 1}).badges, isEmpty);
    });

    test('badges falls back to empty on a non-list value (is List guard)', () {
      // FIXED: `badges` now guards with `is List` (like covers/socialStats), so a
      // malformed non-list value returns an empty list instead of throwing.
      expect(UserProfileModel.fromJson(const {'id': 1, 'badges': 'nope'}).badges, isEmpty);
      expect(UserProfileModel.fromJson(const {'id': 1, 'badges': 42}).badges, isEmpty);
    });

    test('badges parses a real list', () {
      final m = UserProfileModel.fromJson(const {'id': 1, 'badges': ['vip', 7]});
      expect(m.badges, ['vip', '7']);
    });

    test('socialStats from ext stats map', () {
      final m = UserProfileModel.fromJson(const {
        'id': 1,
        'stats': {'friends': 10, 'following': 20, 'followers': 30},
      });
      expect(m.socialStats, {'friends': 10, 'following': 20, 'followers': 30});
    });

    test('socialStats defaults missing keys to 0', () {
      final m = UserProfileModel.fromJson(const {
        'id': 1,
        'stats': {'friends': 5},
      });
      expect(m.socialStats, {'friends': 5, 'following': 0, 'followers': 0});
    });

    test('socialStats empty when no stats key', () {
      expect(UserProfileModel.fromJson(const {'id': 1}).socialStats, isEmpty);
    });

    group('age', () {
      test('null when birthday absent or empty', () {
        expect(UserProfileModel.fromJson(const {'id': 1}).age, isNull);
        expect(
          UserProfileModel.fromJson(const {'id': 1, 'profile': {'birthday': ''}})
              .age,
          isNull,
        );
      });

      test('null when birthday unparseable', () {
        final m = UserProfileModel.fromJson(
            const {'id': 1, 'profile': {'birthday': 'not-a-date'}});
        expect(m.age, isNull);
      });

      test('computes a non-negative age for a past birthday', () {
        // 30 years ago — old enough to be stable regardless of run date.
        final dob = DateTime.now().subtract(const Duration(days: 365 * 30));
        final iso =
            '${dob.year.toString().padLeft(4, '0')}-01-01';
        final m = UserProfileModel.fromJson(
            {'id': 1, 'profile': {'birthday': iso}});
        expect(m.age, isNotNull);
        expect(m.age, greaterThanOrEqualTo(29));
        expect(m.age, lessThan(150));
      });

      test('null for an implausible (>150y) age', () {
        final m = UserProfileModel.fromJson(
            const {'id': 1, 'profile': {'birthday': '1500-01-01'}});
        expect(m.age, isNull);
      });

      test('null for a future birthday (negative age)', () {
        final future = DateTime.now().add(const Duration(days: 365 * 5));
        final iso = '${future.year}-01-01';
        final m = UserProfileModel.fromJson(
            {'id': 1, 'profile': {'birthday': iso}});
        expect(m.age, isNull);
      });
    });
  });

  group('UserProfileEntity equality', () {
    test('equal when all props equal', () {
      const a = UserProfileModel(id: 1, name: 'A');
      const b = UserProfileModel(id: 1, name: 'A');
      expect(a, equals(b));
    });
    test('different name breaks equality (props include name)', () {
      const a = UserProfileModel(id: 1, name: 'A');
      const b = UserProfileModel(id: 1, name: 'B');
      expect(a, isNot(equals(b)));
    });
  });
}
