import 'package:audio_room/src/domain/room_entity.dart';
import 'package:audio_room/src/domain/room_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RoomModel.fromJson', () {
    test('parses a full happy-path payload', () {
      final json = {
        'id': 42,
        'num_id': 1001,
        'owner_id': 7,
        'room_name': 'My Room',
        'room_cover': 'cover.png',
        'room_intro': 'intro',
        'room_rule': 'rules',
        'room_background': 'bg.png',
        'has_password': true,
        'mode': 2,
        'room_status': 1,
        'is_afk': false,
        'visitor_count': 15,
        'visitor_images': ['a.png', 'b.png'],
        'room_type': 3,
        'room_class': 4,
        'category_name': 'Music',
        'is_comment_closed': true,
        'free_mic': true,
        'max_admin': 8,
        'owner_name': 'Alice',
        'owner_avatar': 'alice.png',
        'owner_country_flag': 'us',
        'created_at': '2026-01-15T10:30:00Z',
        'empty_seat_icon': 'empty.png',
        'locked_seat_icon': 'locked.png',
        'pinned_message': {'text': 'hi'},
        'is_owner': true,
        'is_admin': false,
        'is_favorite': true,
        'stream_config': {'token': 'xyz'},
      };

      final m = RoomModel.fromJson(json);

      expect(m.id, 42);
      expect(m.numId, 1001);
      expect(m.ownerId, 7);
      expect(m.roomName, 'My Room');
      expect(m.roomCover, 'cover.png');
      expect(m.roomIntro, 'intro');
      expect(m.roomRule, 'rules');
      expect(m.roomBackground, 'bg.png');
      expect(m.hasPassword, true);
      expect(m.mode, 2);
      expect(m.roomStatus, 1);
      expect(m.isAfk, false);
      expect(m.visitorCount, 15);
      expect(m.visitorImages, ['a.png', 'b.png']);
      expect(m.roomTypeId, 3);
      expect(m.roomClassId, 4);
      expect(m.categoryName, 'Music');
      expect(m.isCommentsClosed, true);
      expect(m.freeMic, true);
      expect(m.maxAdmin, 8);
      expect(m.ownerName, 'Alice');
      expect(m.ownerAvatar, 'alice.png');
      expect(m.ownerCountryFlag, 'us');
      expect(m.createdAt, DateTime.utc(2026, 1, 15, 10, 30));
      expect(m.emptySeatIcon, 'empty.png');
      expect(m.lockedSeatIcon, 'locked.png');
      expect(m.pinnedMessage, {'text': 'hi'});
      expect(m.isOwner, true);
      expect(m.isAdmin, false);
      expect(m.isFavorite, true);
      expect(m.streamConfig, {'token': 'xyz'});
    });

    test('applies defaults for an empty payload', () {
      final m = RoomModel.fromJson(<String, dynamic>{});

      expect(m.id, 0);
      expect(m.numId, 0);
      expect(m.ownerId, 0);
      expect(m.roomName, '');
      expect(m.roomCover, isNull);
      expect(m.hasPassword, false);
      expect(m.mode, 9); // default seat mode
      expect(m.roomStatus, 1);
      expect(m.isAfk, false);
      expect(m.visitorCount, 0);
      expect(m.visitorImages, isEmpty);
      expect(m.roomTypeId, isNull);
      expect(m.roomClassId, isNull);
      expect(m.categoryName, isNull);
      expect(m.isCommentsClosed, false);
      expect(m.freeMic, false);
      expect(m.maxAdmin, 4); // default
      expect(m.createdAt, isNull);
      expect(m.pinnedMessage, isNull);
      expect(m.isOwner, isNull);
      expect(m.isAdmin, isNull);
      expect(m.isFavorite, false);
      expect(m.streamConfig, isNull);
    });

    test('coerces string ints/bools (_toInt / _toBool)', () {
      final m = RoomModel.fromJson({
        'id': '55',
        'num_id': '2002',
        'owner_id': '9',
        'mode': '1',
        'has_password': '1',
        'is_afk': 'true',
        'is_comment_closed': '0',
        'free_mic': 'false',
        'visitor_count': '7',
      });

      expect(m.id, 55);
      expect(m.numId, 2002);
      expect(m.ownerId, 9);
      expect(m.mode, 1);
      expect(m.hasPassword, true); // '1'
      expect(m.isAfk, true); // 'true'
      expect(m.isCommentsClosed, false); // '0'
      expect(m.freeMic, false); // 'false'
      expect(m.visitorCount, 7);
    });

    test('coerces numeric (double) ids via num.toInt', () {
      final m = RoomModel.fromJson({'id': 12.0, 'visitor_count': 9.9});
      expect(m.id, 12);
      expect(m.visitorCount, 9); // truncated
    });

    test('integer bool flags: non-zero true, zero false', () {
      final m = RoomModel.fromJson({'has_password': 1, 'free_mic': 0});
      expect(m.hasPassword, true);
      expect(m.freeMic, false);
    });

    test('unparseable string id falls back to 0', () {
      final m = RoomModel.fromJson({'id': 'not-a-number'});
      expect(m.id, 0);
    });

    test('visitor_images maps non-string elements via toString', () {
      final m = RoomModel.fromJson({
        'visitor_images': [1, 2.5, 'c'],
      });
      expect(m.visitorImages, ['1', '2.5', 'c']);
    });

    test('invalid created_at string yields null (tryParse)', () {
      final m = RoomModel.fromJson({'created_at': 'garbage-date'});
      expect(m.createdAt, isNull);
    });
  });

  group('RoomModel.copyWith', () {
    RoomModel base() => RoomModel.fromJson({
          'id': 1,
          'num_id': 2,
          'owner_id': 3,
          'room_name': 'Original',
          'room_background': 'bg.png',
          'empty_seat_icon': 'empty.png',
          'locked_seat_icon': 'locked.png',
          'pinned_message': {'a': 1},
          'is_admin': true,
          'is_favorite': false,
        });

    test('no-arg copy keeps all values', () {
      final b = base();
      final c = b.copyWith();
      expect(c.roomName, 'Original');
      expect(c.roomBackground, 'bg.png');
      expect(c.emptySeatIcon, 'empty.png');
      expect(c.lockedSeatIcon, 'locked.png');
      expect(c.pinnedMessage, {'a': 1});
      expect(c.isAdmin, true);
      expect(c.isFavorite, false);
      // Equatable equality keyed on id.
      expect(c, equals(b));
    });

    test('overrides only requested scalar fields', () {
      final c = base().copyWith(
        roomName: 'New',
        isFavorite: true,
        visitorCount: 99,
      );
      expect(c.roomName, 'New');
      expect(c.isFavorite, true);
      expect(c.visitorCount, 99);
      // untouched
      expect(c.isAdmin, true);
    });

    test('nullable function-wrapped fields can be set to null explicitly', () {
      final c = base().copyWith(
        roomBackground: () => null,
        emptySeatIcon: () => null,
        lockedSeatIcon: () => null,
        pinnedMessage: () => null,
      );
      expect(c.roomBackground, isNull);
      expect(c.emptySeatIcon, isNull);
      expect(c.lockedSeatIcon, isNull);
      expect(c.pinnedMessage, isNull);
    });

    test('nullable function-wrapped fields can be set to a new value', () {
      final c = base().copyWith(
        roomBackground: () => 'new-bg.png',
        pinnedMessage: () => {'b': 2},
      );
      expect(c.roomBackground, 'new-bg.png');
      expect(c.pinnedMessage, {'b': 2});
    });

    test('omitting a function-wrapped field preserves the original', () {
      final c = base().copyWith(roomName: 'x');
      expect(c.roomBackground, 'bg.png');
      expect(c.pinnedMessage, {'a': 1});
    });
  });

  group('RoomEntity equality', () {
    test('two rooms with same id are equal regardless of other fields', () {
      const a = RoomEntity(id: 5, numId: 1, ownerId: 1, roomName: 'A');
      const b = RoomEntity(id: 5, numId: 2, ownerId: 2, roomName: 'B');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different ids are not equal', () {
      const a = RoomEntity(id: 5, numId: 1, ownerId: 1, roomName: 'A');
      const b = RoomEntity(id: 6, numId: 1, ownerId: 1, roomName: 'A');
      expect(a, isNot(equals(b)));
    });

    test('entity defaults match documented values', () {
      const e = RoomEntity(id: 1, numId: 1, ownerId: 1, roomName: 'x');
      expect(e.mode, 9);
      expect(e.roomStatus, 1);
      expect(e.maxAdmin, 4);
      expect(e.hasPassword, false);
      expect(e.visitorImages, isEmpty);
    });
  });
}
