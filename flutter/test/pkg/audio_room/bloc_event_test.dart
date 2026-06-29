import 'package:audio_room/src/presentation/bloc/create_room/create_room_bloc.dart';
import 'package:audio_room/src/presentation/bloc/room_list/room_list_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RoomListEvent equality (Equatable props)', () {
    test('SearchRoomsEvent equality keyed on query', () {
      expect(
        const SearchRoomsEvent(query: 'abc'),
        equals(const SearchRoomsEvent(query: 'abc')),
      );
      expect(
        const SearchRoomsEvent(query: 'abc'),
        isNot(equals(const SearchRoomsEvent(query: 'xyz'))),
      );
    });

    test('SelectCategoryEvent equality (incl. null)', () {
      expect(
        const SelectCategoryEvent(categoryId: 3),
        equals(const SelectCategoryEvent(categoryId: 3)),
      );
      expect(
        const SelectCategoryEvent(),
        equals(const SelectCategoryEvent()),
      );
      expect(
        const SelectCategoryEvent(categoryId: 3),
        isNot(equals(const SelectCategoryEvent())),
      );
    });

    test('ToggleFavoriteEvent equality keyed on roomId', () {
      expect(
        const ToggleFavoriteEvent(roomId: 1),
        equals(const ToggleFavoriteEvent(roomId: 1)),
      );
      expect(
        const ToggleFavoriteEvent(roomId: 1),
        isNot(equals(const ToggleFavoriteEvent(roomId: 2))),
      );
    });

    test('ChangeViewModeEvent and ChangeSortEvent carry payloads', () {
      expect(const ChangeViewModeEvent(isGrid: true).isGrid, true);
      expect(const ChangeSortEvent(sortBy: 'oldest').sortBy, 'oldest');
      expect(
        const ChangeViewModeEvent(isGrid: true),
        equals(const ChangeViewModeEvent(isGrid: true)),
      );
    });

    test('parameterless events have empty props and are equal', () {
      expect(const LoadRoomsEvent(), equals(const LoadRoomsEvent()));
      expect(const LoadCategoriesEvent(), equals(const LoadCategoriesEvent()));
      expect(const LoadRoomsEvent().props, isEmpty);
    });
  });

  group('CreateRoomEvent equality', () {
    test('SubmitCreateRoomEvent equality across all props', () {
      const a = SubmitCreateRoomEvent(
        name: 'Room',
        mode: 1,
        intro: 'i',
        roomType: 2,
        password: 'p',
        emptySeatIconPreset: 'star',
      );
      const b = SubmitCreateRoomEvent(
        name: 'Room',
        mode: 1,
        intro: 'i',
        roomType: 2,
        password: 'p',
        emptySeatIconPreset: 'star',
      );
      expect(a, equals(b));
    });

    test('SubmitCreateRoomEvent differs when a field differs', () {
      const a = SubmitCreateRoomEvent(name: 'Room', mode: 1);
      const b = SubmitCreateRoomEvent(name: 'Room', mode: 2);
      expect(a, isNot(equals(b)));
    });

    test('parameterless create events equal', () {
      expect(const LoadRoomTypesEvent(), equals(const LoadRoomTypesEvent()));
      expect(const CheckMyRoomEvent(), equals(const CheckMyRoomEvent()));
    });
  });
}
