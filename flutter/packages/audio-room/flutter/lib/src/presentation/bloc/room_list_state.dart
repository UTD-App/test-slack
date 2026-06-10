part of 'room_list_bloc.dart';

class RoomListState extends Equatable {
  final List<RoomModel> rooms;
  final List<RoomCategoryModel> categories;
  final int? selectedCategoryId;
  final String? searchQuery;
  final RequestState roomsState;
  final RequestState categoriesState;
  final int currentPage;
  final bool hasMore;
  final RoomModel? myRoom;
  final String? message;

  const RoomListState({
    this.rooms = const [],
    this.categories = const [],
    this.selectedCategoryId,
    this.searchQuery,
    this.roomsState = RequestState.idle,
    this.categoriesState = RequestState.idle,
    this.currentPage = 1,
    this.hasMore = false,
    this.myRoom,
    this.message,
  });

  RoomListState copyWith({
    List<RoomModel>? rooms,
    List<RoomCategoryModel>? categories,
    int? selectedCategoryId,
    String? searchQuery,
    RequestState? roomsState,
    RequestState? categoriesState,
    int? currentPage,
    bool? hasMore,
    RoomModel? myRoom,
    String? message,
  }) {
    return RoomListState(
      rooms: rooms ?? this.rooms,
      categories: categories ?? this.categories,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      searchQuery: searchQuery ?? this.searchQuery,
      roomsState: roomsState ?? this.roomsState,
      categoriesState: categoriesState ?? this.categoriesState,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      myRoom: myRoom ?? this.myRoom,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [
        rooms,
        categories,
        selectedCategoryId,
        searchQuery,
        roomsState,
        categoriesState,
        currentPage,
        hasMore,
        myRoom,
        message,
      ];
}
