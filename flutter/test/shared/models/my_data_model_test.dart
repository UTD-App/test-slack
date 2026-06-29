import 'package:flutter_test/flutter_test.dart';
import 'package:utd_app/shared/models/country_model.dart';
import 'package:utd_app/shared/models/my_data_model.dart';
import 'package:utd_app/shared/models/profile_room_model.dart';

/// Pure-Dart unit tests for [MyDataModel].
///
/// Covers backend key mapping (`firebase_uuid` -> uid, `notification_id`,
/// `auth_token`, `is_first`, `online_time`), nested profile/country parsing,
/// the Hive `_Map<dynamic,dynamic>` coercion seam, toJson, and copyWith.
void main() {
  Map<String, dynamic> fullJson() => <String, dynamic>{
        'id': 7,
        'firebase_uuid': 'fb-123',
        'notification_id': 'notif-9',
        'name': 'Ahmed',
        'email': 'a@b.com',
        'phone': '0100',
        'uuid': '900',
        'bio': 'hello',
        'is_first': true,
        'online_time': '2026-06-29 10:00',
        'auth_token': 'tok-xyz',
        'profile': <String, dynamic>{
          'image': 'avatar.png',
          'gender': 1,
          'image_id': 'img1',
          'birthday': '1998-01-01',
          'age': 27,
        },
        'country': <String, dynamic>{
          'id': 20,
          'name': 'Egypt',
          'flag': 'eg.png',
          'phone_code': '+20',
          'iso': 'EG',
          'e_name': 'Egypt',
        },
      };

  group('MyDataModel.fromJson', () {
    test('happy path: scalar fields + key mapping', () {
      final m = MyDataModel.fromJson(fullJson());

      expect(m.id, 7);
      expect(m.uid, 'fb-123'); // firebase_uuid -> uid
      expect(m.notificationId, 'notif-9');
      expect(m.name, 'Ahmed');
      expect(m.email, 'a@b.com');
      expect(m.phone, '0100');
      expect(m.uuid, '900');
      expect(m.bio, 'hello');
      expect(m.isFirst, true);
      expect(m.onlineTime, '2026-06-29 10:00');
      expect(m.authToken, 'tok-xyz');
    });

    test('happy path: nested profile + country parsed into sub-models', () {
      final m = MyDataModel.fromJson(fullJson());

      expect(m.profile, isA<ProfileRoomModel>());
      expect(m.profile!.image, 'avatar.png');
      expect(m.profile!.gender, 1);
      expect(m.profile!.age, 27);

      expect(m.country, isA<CountryModel>());
      expect(m.country!.id, 20);
      expect(m.country!.photo, 'eg.png'); // flag -> photo
      expect(m.country!.phoneCode, '+20');
    });

    test('empty json: scalar defaults, null nested objects', () {
      final m = MyDataModel.fromJson(<String, dynamic>{});

      expect(m.id, 0);
      expect(m.uid, '');
      expect(m.notificationId, '');
      expect(m.name, '');
      expect(m.email, '');
      expect(m.phone, '');
      expect(m.uuid, '');
      expect(m.bio, '');
      expect(m.isFirst, false);
      expect(m.onlineTime, '');
      expect(m.authToken, '');
      // nested objects absent -> null (the `is Map` guard returns null).
      expect(m.profile, isNull);
      expect(m.country, isNull);
    });

    test('explicit null profile/country -> null sub-models', () {
      final m = MyDataModel.fromJson(<String, dynamic>{
        'profile': null,
        'country': null,
      });

      expect(m.profile, isNull);
      expect(m.country, isNull);
    });

    test('Hive round-trip: nested Map<dynamic,dynamic> is coerced, not crashed',
        () {
      // Hive returns nested maps as _Map<dynamic, dynamic>; the model copies
      // them via Map<String,dynamic>.from before handing to the sub-model.
      final Map<String, dynamic> json = <String, dynamic>{
        'id': 5,
        // dynamic-keyed nested maps (what a Hive read looks like)
        'profile': <dynamic, dynamic>{'image': 'h.png', 'gender': 2, 'age': 30},
        'country': <dynamic, dynamic>{'id': 1, 'name': 'X', 'flag': 'x.png'},
      };

      final m = MyDataModel.fromJson(json);

      expect(m.profile, isA<ProfileRoomModel>());
      expect(m.profile!.image, 'h.png');
      expect(m.profile!.gender, 2);
      expect(m.country, isA<CountryModel>());
      expect(m.country!.name, 'X');
      expect(m.country!.photo, 'x.png');
    });

    test('partial profile json fills sub-model defaults', () {
      final m = MyDataModel.fromJson(<String, dynamic>{
        'profile': <String, dynamic>{'image': 'only.png'},
      });

      expect(m.profile!.image, 'only.png');
      expect(m.profile!.gender, 0);
      expect(m.profile!.age, 0);
      expect(m.profile!.imageId, '');
    });
  });

  group('MyDataModel.toJson', () {
    test('serializes scalars + nested profile with backend keys', () {
      final m = MyDataModel.fromJson(fullJson());
      final out = m.toJson();

      expect(out['id'], 7);
      expect(out['firebase_uuid'], 'fb-123');
      expect(out['notification_id'], 'notif-9');
      expect(out['name'], 'Ahmed');
      expect(out['email'], 'a@b.com');
      expect(out['phone'], '0100');
      expect(out['uuid'], '900');
      expect(out['bio'], 'hello');
      expect(out['is_first'], true);
      expect(out['online_time'], '2026-06-29 10:00');
      expect(out['auth_token'], 'tok-xyz');

      // profile persisted so the avatar survives a cache round-trip.
      expect(out['profile'], isA<Map<String, dynamic>>());
      expect((out['profile'] as Map)['image'], 'avatar.png');
    });

    test('toJson omits country entirely (only profile is persisted)', () {
      // Documenting current behavior: toJson does NOT serialize country.
      final m = MyDataModel.fromJson(fullJson());
      final out = m.toJson();

      expect(out.containsKey('country'), isFalse);
    });

    test('null profile -> profile key present but null', () {
      final m = MyDataModel.fromJson(<String, dynamic>{'id': 1});
      final out = m.toJson();

      expect(out.containsKey('profile'), isTrue);
      expect(out['profile'], isNull);
    });

    test('round-trip toJson -> fromJson preserves scalars + profile (not country)',
        () {
      final original = MyDataModel.fromJson(fullJson());
      final round = MyDataModel.fromJson(original.toJson());

      expect(round.id, original.id);
      expect(round.uid, original.uid);
      expect(round.name, original.name);
      expect(round.authToken, original.authToken);
      expect(round.profile, equals(original.profile));
      // country is lost across the toJson round-trip (not serialized).
      expect(round.country, isNull);
    });
  });

  group('MyDataModel.copyWith', () {
    test('overrides only provided fields, keeps the rest', () {
      final m = MyDataModel.fromJson(fullJson());

      final updated = m.copyWith(name: 'New', authToken: 'tok-new');

      expect(updated.name, 'New');
      expect(updated.authToken, 'tok-new');
      // untouched
      expect(updated.id, 7);
      expect(updated.uid, 'fb-123');
      expect(updated.email, 'a@b.com');
      expect(updated.profile, equals(m.profile));
      expect(updated.country, equals(m.country));
    });

    test('no args returns an equal value object', () {
      final m = MyDataModel.fromJson(fullJson());
      expect(m.copyWith(), equals(m));
    });

    test('can replace nested profile + country', () {
      final m = MyDataModel.fromJson(fullJson());
      const newProfile = ProfileRoomModel(image: 'p2.png', gender: 2);
      const newCountry = CountryModel(id: 99, name: 'Z');

      final updated = m.copyWith(profile: newProfile, country: newCountry);

      expect(updated.profile, newProfile);
      expect(updated.country, newCountry);
    });
  });
}
