import 'package:flutter_test/flutter_test.dart';
import 'package:utd_app/shared/entities/profile_room_entity.dart';
import 'package:utd_app/shared/models/profile_room_model.dart';

/// Pure-Dart unit tests for [ProfileRoomModel] (fromJson + toJson round-trip).
void main() {
  group('ProfileRoomModel.fromJson', () {
    test('happy path: all fields populated', () {
      final json = <String, dynamic>{
        'image': 'https://cdn/avatar.png',
        'gender': 2,
        'image_id': 'img-42',
        'birthday': '1998-05-01',
        'age': 27,
      };

      final p = ProfileRoomModel.fromJson(json);

      expect(p.image, 'https://cdn/avatar.png');
      expect(p.gender, 2);
      expect(p.imageId, 'img-42');
      expect(p.birthday, '1998-05-01');
      expect(p.age, 27);
    });

    test('empty json: defaults (empty strings / 0)', () {
      final p = ProfileRoomModel.fromJson(<String, dynamic>{});

      expect(p.image, '');
      expect(p.gender, 0);
      expect(p.imageId, '');
      expect(p.birthday, '');
      expect(p.age, 0);
    });

    test('explicit nulls coerce to defaults', () {
      final json = <String, dynamic>{
        'image': null,
        'gender': null,
        'image_id': null,
        'birthday': null,
        'age': null,
      };

      final p = ProfileRoomModel.fromJson(json);

      expect(p.image, '');
      expect(p.gender, 0);
      expect(p.imageId, '');
      expect(p.birthday, '');
      expect(p.age, 0);
    });
  });

  group('ProfileRoomModel.toJson', () {
    test('serializes all fields with backend keys', () {
      const p = ProfileRoomModel(
        image: 'a.png',
        gender: 1,
        imageId: 'id1',
        birthday: '2000-01-01',
        age: 26,
      );

      expect(p.toJson(), <String, dynamic>{
        'image': 'a.png',
        'gender': 1,
        'image_id': 'id1',
        'birthday': '2000-01-01',
        'age': 26,
      });
    });

    test('round-trip fromJson -> toJson -> fromJson preserves data', () {
      final src = <String, dynamic>{
        'image': 'r.png',
        'gender': 2,
        'image_id': 'rid',
        'birthday': '1990-12-12',
        'age': 35,
      };

      final first = ProfileRoomModel.fromJson(src);
      final round = ProfileRoomModel.fromJson(first.toJson());

      expect(round, equals(first));
    });
  });

  test('is an Equatable ProfileRoomEntity', () {
    final a = ProfileRoomModel.fromJson({'image': 'x', 'age': 1});
    final b = ProfileRoomModel.fromJson({'image': 'x', 'age': 1});

    expect(a, isA<ProfileRoomEntity>());
    expect(a, equals(b));
  });
}
