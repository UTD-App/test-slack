import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/shared/core/base_response.dart';
import 'package:utd_app/shared/core/enums.dart';

import '../../domain/audio_room_repository.dart';
import '../../domain/room_category_model.dart';
import '../../domain/room_model.dart';

part 'room_list_event.dart';
part 'room_list_state.dart';

class RoomListBloc extends Bloc<RoomListEvent, RoomListState> {
  final AudioRoomRepository repository;

  RoomListBloc({required this.repository}) : super(const RoomListState()) {
    on<LoadRoomsEvent>(_onLoadRooms);
    on<LoadMoreRoomsEvent>(_onLoadMore);
    on<LoadCategoriesEvent>(_onLoadCategories);
    on<SearchRoomsEvent>(_onSearchRooms);
    on<SelectCategoryEvent>(_onSelectCategory);
    on<ToggleFavoriteEvent>(_onToggleFavorite);
    on<LoadMyRoomEvent>(_onLoadMyRoom);
  }

  void _emitRoomsResult(
    Emitter<RoomListState> emit,
    Result<BaseResponse<List<RoomModel>>> result, {
    List<RoomModel> existingRooms = const [],
    int page = 1,
  }) {
    switch (result) {
      case Success(data: final data):
        final rooms = <RoomModel>[...existingRooms, ...(data.data ?? [])];
        final paginates = data.paginates;
        emit(state.copyWith(
          rooms: rooms,
          roomsState: rooms.isEmpty ? RequestState.empty : RequestState.loaded,
          currentPage: page,
          hasMore: paginates != null
              ? paginates.currentPage < paginates.lastPage
              : false,
        ));
      case Failure(message: final message):
        if (existingRooms.isEmpty) {
          emit(state.copyWith(roomsState: RequestState.error, message: message));
        }
    }
  }

  Future<void> _onLoadRooms(
    LoadRoomsEvent event,
    Emitter<RoomListState> emit,
  ) async {
    emit(state.copyWith(roomsState: RequestState.loading));

    final result = await repository.getRooms(
      page: 1,
      categoryId: state.selectedCategoryId,
      search: state.searchQuery,
    );

    _emitRoomsResult(emit, result);
  }

  Future<void> _onLoadMore(
    LoadMoreRoomsEvent event,
    Emitter<RoomListState> emit,
  ) async {
    if (!state.hasMore) return;

    final nextPage = state.currentPage + 1;
    final result = await repository.getRooms(
      page: nextPage,
      categoryId: state.selectedCategoryId,
      search: state.searchQuery,
    );

    _emitRoomsResult(
      emit,
      result,
      existingRooms: state.rooms,
      page: nextPage,
    );
  }

  Future<void> _onLoadCategories(
    LoadCategoriesEvent event,
    Emitter<RoomListState> emit,
  ) async {
    emit(state.copyWith(categoriesState: RequestState.loading));

    final result = await repository.getCategories();

    switch (result) {
      case Success(data: final data):
        emit(state.copyWith(
          categories: data.data ?? [],
          categoriesState: RequestState.loaded,
        ));
      case Failure(message: final message):
        emit(state.copyWith(
          categoriesState: RequestState.error,
          message: message,
        ));
    }
  }

  Future<void> _onSearchRooms(
    SearchRoomsEvent event,
    Emitter<RoomListState> emit,
  ) async {
    emit(state.copyWith(
      searchQuery: event.query,
      roomsState: RequestState.loading,
    ));

    final result = await repository.getRooms(
      page: 1,
      categoryId: state.selectedCategoryId,
      search: event.query.isEmpty ? null : event.query,
    );

    _emitRoomsResult(emit, result);
  }

  Future<void> _onSelectCategory(
    SelectCategoryEvent event,
    Emitter<RoomListState> emit,
  ) async {
    emit(state.copyWith(
      selectedCategoryId: event.categoryId,
      roomsState: RequestState.loading,
    ));

    final result = await repository.getRooms(
      page: 1,
      categoryId: event.categoryId,
      search: state.searchQuery,
    );

    _emitRoomsResult(emit, result);
  }

  Future<void> _onToggleFavorite(
    ToggleFavoriteEvent event,
    Emitter<RoomListState> emit,
  ) async {
    await repository.toggleFavorite(event.roomId);
  }

  Future<void> _onLoadMyRoom(
    LoadMyRoomEvent event,
    Emitter<RoomListState> emit,
  ) async {
    final result = await repository.getMyRoom();

    switch (result) {
      case Success(data: final data):
        emit(state.copyWith(myRoom: data.data));
      case Failure():
        break;
    }
  }
}
