import 'package:audio_room_charisma/audio_room_charisma.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utd_app/shared/core/enums.dart';

void main() {
  group('CharismaModel.fromJson', () {
    test('parses user_id/total/position', () {
      final m = CharismaModel.fromJson({
        'user_id': 7,
        'total': '12345',
        'position': 3,
      });
      expect(m.userId, 7);
      expect(m.total, '12345');
      expect(m.position, 3);
    });

    test('total coerced to string from a numeric value', () {
      final m = CharismaModel.fromJson({'user_id': 1, 'total': 500, 'position': 1});
      expect(m.total, '500');
    });

    test('total defaults to "0" when null', () {
      final m = CharismaModel.fromJson({'user_id': 1, 'position': 1});
      expect(m.total, '0');
    });

    test('position defaults to 0 when null/absent', () {
      final m = CharismaModel.fromJson({'user_id': 1, 'total': '5'});
      expect(m.position, 0);
    });

    test('equality is keyed on userId', () {
      const a = CharismaEntity(userId: 1, total: '5', position: 1);
      const b = CharismaEntity(userId: 1, total: '999', position: 9);
      expect(a, equals(b));
      const c = CharismaEntity(userId: 2, total: '5', position: 1);
      expect(a, isNot(equals(c)));
    });
  });

  group('CharismaLevelModel.fromJson', () {
    test('parses a full level', () {
      final l = CharismaLevelModel.fromJson({
        'level': 5,
        'points': 1000,
        'image': 'lvl5.png',
      });
      expect(l.level, 5);
      expect(l.points, 1000);
      expect(l.image, 'lvl5.png');
    });

    test('points/image default when null', () {
      final l = CharismaLevelModel.fromJson({'level': 2});
      expect(l.points, 0);
      expect(l.image, '');
    });

    test('equality keyed on level', () {
      const a = CharismaLevelModel(level: 1, points: 10, image: 'a');
      const b = CharismaLevelModel(level: 1, points: 99, image: 'b');
      expect(a, equals(b));
    });
  });

  group('CharismaState', () {
    test('defaults', () {
      const s = CharismaState();
      expect(s.data, isNull);
      expect(s.charismaActive, false);
      expect(s.levels, isEmpty);
      expect(s.levelsState, RequestState.idle);
      expect(s.dataState, RequestState.idle);
      expect(s.statusState, RequestState.idle);
      expect(s.resetState, RequestState.idle);
    });

    test('copyWith overrides requested fields only', () {
      const s = CharismaState();
      final c = s.copyWith(
        charismaActive: true,
        data: [const CharismaModel(userId: 1, total: '5', position: 1)],
        dataState: RequestState.loaded,
      );
      expect(c.charismaActive, true);
      expect(c.data!.single.userId, 1);
      expect(c.dataState, RequestState.loaded);
      // untouched
      expect(c.levelsState, RequestState.idle);
    });

    test('equatable equality', () {
      const a = CharismaState(charismaActive: true, message: 'm');
      const b = CharismaState(charismaActive: true, message: 'm');
      expect(a, equals(b));
    });
  });
}
