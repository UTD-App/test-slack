part of 'room_list_bloc.dart';

sealed class RoomListEvent extends Equatable {
  const RoomListEvent();

  @override
  List<Object?> get props => [];
}

class LoadRoomsEvent extends RoomListEvent {
  const LoadRoomsEvent();
}

class LoadMoreRoomsEvent extends RoomListEvent {
  const LoadMoreRoomsEvent();
}

class LoadCategoriesEvent extends RoomListEvent {
  const LoadCategoriesEvent();
}

class SearchRoomsEvent extends RoomListEvent {
  final String query;

  const SearchRoomsEvent({required this.query});

  @override
  List<Object?> get props => [query];
}

class SelectCategoryEvent extends RoomListEvent {
  final int? categoryId;

  const SelectCategoryEvent({this.categoryId});

  @override
  List<Object?> get props => [categoryId];
}

class ToggleFavoriteEvent extends RoomListEvent {
  final int roomId;

  const ToggleFavoriteEvent({required this.roomId});

  @override
  List<Object?> get props => [roomId];
}

class LoadMyRoomEvent extends RoomListEvent {
  const LoadMyRoomEvent();
}

class LoadFavoritesEvent extends RoomListEvent {
  const LoadFavoritesEvent();
}

class ChangeViewModeEvent extends RoomListEvent {
  final bool isGrid;

  const ChangeViewModeEvent({required this.isGrid});

  @override
  List<Object?> get props => [isGrid];
}

class ChangeSortEvent extends RoomListEvent {
  final String sortBy;

  const ChangeSortEvent({required this.sortBy});

  @override
  List<Object?> get props => [sortBy];
}

class SearchFavoritesEvent extends RoomListEvent {
  final String query;

  const SearchFavoritesEvent({required this.query});

  @override
  List<Object?> get props => [query];
}
