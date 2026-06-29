import 'package:audio_room/src/domain/room_admin_model.dart';
import 'package:audio_room/src/domain/room_category_model.dart';
import 'package:audio_room/src/domain/room_model.dart';
import 'package:audio_room/src/domain/room_visitor_model.dart';
import 'package:audio_room/src/presentation/bloc/admin/admin_bloc.dart';
import 'package:audio_room/src/presentation/bloc/blacklist/blacklist_bloc.dart';
import 'package:audio_room/src/presentation/bloc/create_room/create_room_bloc.dart';
import 'package:audio_room/src/presentation/bloc/room_list/room_list_bloc.dart';
import 'package:audio_room/src/presentation/bloc/room_management/room_management_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utd_app/shared/core/enums.dart';

RoomModel _room(int id) => RoomModel.fromJson({'id': id, 'room_name': 'r$id'});

void main() {
  group('RoomListState', () {
    test('defaults', () {
      const s = RoomListState();
      expect(s.rooms, isEmpty);
      expect(s.favoriteRooms, isEmpty);
      expect(s.categories, isEmpty);
      expect(s.selectedCategoryId, isNull);
      expect(s.roomsState, RequestState.idle);
      expect(s.currentPage, 1);
      expect(s.hasMore, false);
      expect(s.isGridView, true);
      expect(s.sortBy, 'visitors');
    });

    test('copyWith overrides only requested fields', () {
      const s = RoomListState();
      final c = s.copyWith(
        rooms: [_room(1)],
        roomsState: RequestState.loaded,
        currentPage: 3,
        isGridView: false,
        sortBy: 'newest',
      );
      expect(c.rooms.single.id, 1);
      expect(c.roomsState, RequestState.loaded);
      expect(c.currentPage, 3);
      expect(c.isGridView, false);
      expect(c.sortBy, 'newest');
      // untouched
      expect(c.favoritesState, RequestState.idle);
      expect(c.hasMore, false);
    });

    test('equatable: equal states compare equal', () {
      final a = const RoomListState().copyWith(rooms: [_room(1)]);
      final b = const RoomListState().copyWith(rooms: [_room(1)]);
      expect(a, equals(b));
    });

    test('equatable: differing rooms are not equal', () {
      final a = const RoomListState().copyWith(rooms: [_room(1)]);
      final b = const RoomListState().copyWith(rooms: [_room(2)]);
      expect(a, isNot(equals(b)));
    });
  });

  group('CreateRoomState', () {
    test('hasExistingRoom reflects existingRoom presence', () {
      const empty = CreateRoomState();
      expect(empty.hasExistingRoom, false);
      final withRoom = empty.copyWith(existingRoom: _room(9));
      expect(withRoom.hasExistingRoom, true);
    });

    test('copyWith clearExistingRoom nulls it out', () {
      final s = const CreateRoomState().copyWith(existingRoom: _room(9));
      expect(s.hasExistingRoom, true);
      final cleared = s.copyWith(clearExistingRoom: true);
      expect(cleared.existingRoom, isNull);
      expect(cleared.hasExistingRoom, false);
    });

    test('copyWith without clear flag preserves existingRoom', () {
      final s = const CreateRoomState().copyWith(existingRoom: _room(9));
      final c = s.copyWith(createState: RequestState.loading);
      expect(c.existingRoom?.id, 9);
      expect(c.createState, RequestState.loading);
    });

    test('types list copyWith', () {
      final types = [RoomCategoryModel.fromJson({'id': 1, 'name': 'A'})];
      final s = const CreateRoomState().copyWith(types: types, typesState: RequestState.loaded);
      expect(s.types.single.id, 1);
      expect(s.typesState, RequestState.loaded);
    });
  });

  group('AdminState', () {
    test('defaults + copyWith', () {
      const s = AdminState();
      expect(s.admins, isEmpty);
      expect(s.adminsState, RequestState.idle);

      final admins = [RoomAdminModel.fromJson({'id': 1, 'name': 'A'})];
      final c = s.copyWith(admins: admins, adminsState: RequestState.loaded);
      expect(c.admins.single.id, 1);
      expect(c.adminsState, RequestState.loaded);
    });

    test('equatable equality', () {
      const a = AdminState(message: 'm');
      const b = AdminState(message: 'm');
      expect(a, equals(b));
    });
  });

  group('BlacklistState', () {
    test('defaults + copyWith', () {
      const s = BlacklistState();
      expect(s.blacklist, isEmpty);
      expect(s.blacklistState, RequestState.idle);

      final c = s.copyWith(
        blacklistState: RequestState.empty,
        message: 'none',
      );
      expect(c.blacklistState, RequestState.empty);
      expect(c.message, 'none');
    });
  });

  group('RoomManagementState', () {
    test('defaults', () {
      const s = RoomManagementState();
      expect(s.enteredRoom, isNull);
      expect(s.enterState, RequestState.idle);
      expect(s.visitors, isEmpty);
      expect(s.visitorsPage, 1);
      expect(s.hasMoreVisitors, false);
    });

    test('clearEnteredRoom nulls room out', () {
      final s = const RoomManagementState().copyWith(enteredRoom: _room(3));
      expect(s.enteredRoom?.id, 3);
      final cleared = s.copyWith(clearEnteredRoom: true);
      expect(cleared.enteredRoom, isNull);
    });

    test('clearUpdatedRoom nulls updatedRoom out', () {
      final s = const RoomManagementState().copyWith(updatedRoom: _room(5));
      expect(s.updatedRoom?.id, 5);
      final cleared = s.copyWith(clearUpdatedRoom: true);
      expect(cleared.updatedRoom, isNull);
    });

    test('visitors pagination copyWith', () {
      final visitors = [RoomVisitorModel.fromJson({'id': 1, 'name': 'V'})];
      final s = const RoomManagementState().copyWith(
        visitors: visitors,
        visitorsPage: 2,
        hasMoreVisitors: true,
      );
      expect(s.visitors.single.id, 1);
      expect(s.visitorsPage, 2);
      expect(s.hasMoreVisitors, true);
    });

    test('clear flags take precedence over passed value', () {
      // clearEnteredRoom wins even if enteredRoom also supplied.
      final s = const RoomManagementState().copyWith(
        enteredRoom: _room(1),
        clearEnteredRoom: true,
      );
      expect(s.enteredRoom, isNull);
    });
  });
}
