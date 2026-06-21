part of 'room_list_bloc.dart';

class RoomListState extends Equatable {
  final List<RoomModel> rooms;
  final List<RoomModel> favoriteRooms;
  final List<RoomCategoryModel> categories;
  final int? selectedCategoryId;
  final String? searchQuery;
  final RequestState roomsState;
  final RequestState favoritesState;
  final RequestState categoriesState;
  final int currentPage;
  final bool hasMore;
  final RoomModel? myRoom;
  final String? message;
  final bool isGridView;
  final String sortBy;
  final String? favoritesSearchQuery;

  const RoomListState({
    this.rooms = const [],
    this.favoriteRooms = const [],
    this.categories = const [],
    this.selectedCategoryId,
    this.searchQuery,
    this.roomsState = RequestState.idle,
    this.favoritesState = RequestState.idle,
    this.categoriesState = RequestState.idle,
    this.currentPage = 1,
    this.hasMore = false,
    this.myRoom,
    this.message,
    this.isGridView = true,
    this.sortBy = 'visitors',
    this.favoritesSearchQuery,
  });

  RoomListState copyWith({
    List<RoomModel>? rooms,
    List<RoomModel>? favoriteRooms,
    List<RoomCategoryModel>? categories,
    int? selectedCategoryId,
    String? searchQuery,
    RequestState? roomsState,
    RequestState? favoritesState,
    RequestState? categoriesState,
    int? currentPage,
    bool? hasMore,
    RoomModel? myRoom,
    String? message,
    bool? isGridView,
    String? sortBy,
    String? favoritesSearchQuery,
  }) {
    return RoomListState(
      rooms: rooms ?? this.rooms,
      favoriteRooms: favoriteRooms ?? this.favoriteRooms,
      categories: categories ?? this.categories,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      searchQuery: searchQuery ?? this.searchQuery,
      roomsState: roomsState ?? this.roomsState,
      favoritesState: favoritesState ?? this.favoritesState,
      categoriesState: categoriesState ?? this.categoriesState,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      myRoom: myRoom ?? this.myRoom,
      message: message ?? this.message,
      isGridView: isGridView ?? this.isGridView,
      sortBy: sortBy ?? this.sortBy,
      favoritesSearchQuery: favoritesSearchQuery ?? this.favoritesSearchQuery,
    );
  }

  @override
  List<Object?> get props => [
        rooms,
        favoriteRooms,
        categories,
        selectedCategoryId,
        searchQuery,
        roomsState,
        favoritesState,
        categoriesState,
        currentPage,
        hasMore,
        myRoom,
        message,
        isGridView,
        sortBy,
        favoritesSearchQuery,
      ];
}
