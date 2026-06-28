import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/shared/core/enums.dart';

import '../../../data/pending_exit_manager.dart';
import '../../../domain/audio_room_repository.dart';
import '../../../domain/room_model.dart';
import '../../../domain/room_visitor_model.dart';

part 'room_management_event.dart';
part 'room_management_state.dart';

class RoomManagementBloc
    extends Bloc<RoomManagementEvent, RoomManagementState> {
  final AudioRoomRepository repository;

  RoomManagementBloc({required this.repository})
    : super(const RoomManagementState()) {
    on<EnterRoomEvent>(_onEnterRoom);
    on<ExitRoomEvent>(_onExitRoom);
    on<ToggleRoomFavoriteEvent>(_onToggleFavorite);
    on<UpdateRoomEvent>(_onUpdateRoom);
    on<RemovePasswordEvent>(_onRemovePassword);
    on<ChangeRoomModeEvent>(_onChangeMode);
    on<ToggleCommentsEvent>(_onToggleComments);
    on<SendBannerEvent>(_onSendBanner);
    on<PinMessageEvent>(_onPinMessage);
    on<UnpinMessageEvent>(_onUnpinMessage);
    on<LoadVisitorsEvent>(_onLoadVisitors);
    on<LoadMoreVisitorsEvent>(_onLoadMoreVisitors);
    on<DeleteRoomEvent>(_onDeleteRoom);
  }

  Future<void> _onEnterRoom(
    EnterRoomEvent event,
    Emitter<RoomManagementState> emit,
  ) async {
    emit(state.copyWith(enterState: RequestState.loading));

    final result = await repository.enterRoom(
      event.roomId,
      password: event.password,
    );

    switch (result) {
      case Success(data: final data):
        if (data.data != null) {
          emit(state.copyWith(
            enterState: RequestState.loaded,
            enteredRoom: data.data,
          ));
        } else {
          emit(state.copyWith(
            enterState: RequestState.error,
            message: data.message,
          ));
        }
      case Failure(message: final message):
        emit(state.copyWith(enterState: RequestState.error, message: message));
    }
  }

  Future<void> _onExitRoom(
    ExitRoomEvent event,
    Emitter<RoomManagementState> emit,
  ) async {
    emit(state.copyWith(exitState: RequestState.loading));

    final result = await repository.exitRoom(event.roomId);

    switch (result) {
      case Success():
        emit(state.copyWith(exitState: RequestState.loaded));
      case Failure():
        await PendingExitManager.add(event.roomId);
        emit(state.copyWith(exitState: RequestState.loaded));
    }
  }

  Future<void> _onToggleFavorite(
    ToggleRoomFavoriteEvent event,
    Emitter<RoomManagementState> emit,
  ) async {
    await repository.toggleFavorite(event.roomId);
  }

  Future<void> _onUpdateRoom(
    UpdateRoomEvent event,
    Emitter<RoomManagementState> emit,
  ) async {
    emit(state.copyWith(updateState: RequestState.loading));

    final result = await repository.updateRoom(
      event.roomId,
      name: event.name,
      intro: event.intro,
      rule: event.rule,
      background: event.background,
      backgroundFile: event.backgroundFile,
      password: event.password,
      mode: event.mode,
      roomType: event.roomType,
      roomClass: event.roomClass,
      isCommentsClosed: event.isCommentsClosed,
      freeMic: event.freeMic,
      cover: event.cover,
      emptySeatIcon: event.emptySeatIcon,
      lockedSeatIcon: event.lockedSeatIcon,
      emptySeatIconPreset: event.emptySeatIconPreset,
      lockedSeatIconPreset: event.lockedSeatIconPreset,
      removeBackground: event.removeBackground,
    );

    switch (result) {
      case Success(data: final data):
        emit(
          state.copyWith(
            updateState: RequestState.loaded,
            updatedRoom: data.data,
          ),
        );
      case Failure(message: final message):
        emit(state.copyWith(updateState: RequestState.error, message: message));
    }
  }

  Future<void> _onRemovePassword(
    RemovePasswordEvent event,
    Emitter<RoomManagementState> emit,
  ) async {
    emit(state.copyWith(updateState: RequestState.loading));

    final result = await repository.removePassword(event.roomId);

    switch (result) {
      case Success():
        emit(state.copyWith(updateState: RequestState.loaded));
      case Failure(message: final message):
        emit(state.copyWith(updateState: RequestState.error, message: message));
    }
  }

  Future<void> _onChangeMode(
    ChangeRoomModeEvent event,
    Emitter<RoomManagementState> emit,
  ) async {
    emit(state.copyWith(updateState: RequestState.loading));

    final result = await repository.changeMode(event.roomId, event.mode);

    switch (result) {
      case Success():
        emit(state.copyWith(updateState: RequestState.loaded, clearUpdatedRoom: true));
      case Failure(message: final message):
        emit(state.copyWith(updateState: RequestState.error, message: message));
    }
  }

  Future<void> _onToggleComments(
    ToggleCommentsEvent event,
    Emitter<RoomManagementState> emit,
  ) async {
    final result = await repository.toggleComments(event.roomId, event.closed);

    switch (result) {
      case Success():
        emit(state.copyWith(updateState: RequestState.loaded));
      case Failure(message: final message):
        emit(state.copyWith(updateState: RequestState.error, message: message));
    }
  }

  Future<void> _onPinMessage(
    PinMessageEvent event,
    Emitter<RoomManagementState> emit,
  ) async {
    await repository.pinMessage(event.roomId, event.data);
  }

  Future<void> _onUnpinMessage(
    UnpinMessageEvent event,
    Emitter<RoomManagementState> emit,
  ) async {
    await repository.unpinMessage(event.roomId);
  }

  Future<void> _onSendBanner(
    SendBannerEvent event,
    Emitter<RoomManagementState> emit,
  ) async {
    final result = await repository.sendBanner(event.roomId, event.message);

    switch (result) {
      case Success():
        emit(state.copyWith(updateState: RequestState.loaded));
      case Failure(message: final message):
        emit(state.copyWith(updateState: RequestState.error, message: message));
    }
  }

  Future<void> _onLoadVisitors(
    LoadVisitorsEvent event,
    Emitter<RoomManagementState> emit,
  ) async {
    emit(state.copyWith(visitorsState: RequestState.loading));

    final result = await repository.getRoomUsers(event.roomId, page: 1);

    switch (result) {
      case Success(data: final data):
        final visitors = data.data ?? [];
        final paginates = data.paginates;
        emit(
          state.copyWith(
            visitors: visitors,
            visitorsState: RequestState.loaded,
            visitorsPage: 1,
            hasMoreVisitors: paginates != null
                ? paginates.currentPage < paginates.lastPage
                : false,
          ),
        );
      case Failure(message: final message):
        emit(
          state.copyWith(visitorsState: RequestState.error, message: message),
        );
    }
  }

  bool _isLoadingMoreVisitors = false;

  Future<void> _onLoadMoreVisitors(
    LoadMoreVisitorsEvent event,
    Emitter<RoomManagementState> emit,
  ) async {
    if (!state.hasMoreVisitors || _isLoadingMoreVisitors) return;
    _isLoadingMoreVisitors = true;

    final nextPage = state.visitorsPage + 1;
    final result = await repository.getRoomUsers(event.roomId, page: nextPage);

    switch (result) {
      case Success(data: final data):
        final newVisitors = data.data ?? [];
        final paginates = data.paginates;
        emit(
          state.copyWith(
            visitors: [...state.visitors, ...newVisitors],
            visitorsPage: nextPage,
            hasMoreVisitors: paginates != null
                ? paginates.currentPage < paginates.lastPage
                : false,
          ),
        );
      case Failure():
        break;
    }
    _isLoadingMoreVisitors = false;
  }

  Future<void> _onDeleteRoom(
    DeleteRoomEvent event,
    Emitter<RoomManagementState> emit,
  ) async {
    emit(state.copyWith(deleteState: RequestState.loading));

    final result = await repository.deleteRoom(event.roomId);

    switch (result) {
      case Success():
        emit(state.copyWith(deleteState: RequestState.loaded));
      case Failure(message: final message):
        emit(state.copyWith(deleteState: RequestState.error, message: message));
    }
  }
}
