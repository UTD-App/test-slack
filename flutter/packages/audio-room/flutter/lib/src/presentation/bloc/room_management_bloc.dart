import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/shared/core/enums.dart';

import '../../domain/audio_room_repository.dart';
import '../../domain/room_admin_model.dart';
import '../../domain/room_model.dart';
import '../../domain/room_visitor_model.dart';

part 'room_management_event.dart';
part 'room_management_state.dart';

class RoomManagementBloc
    extends Bloc<RoomManagementEvent, RoomManagementState> {
  final AudioRoomRepository repository;

  RoomManagementBloc({required this.repository})
      : super(const RoomManagementState()) {
    // Settings
    on<UpdateRoomEvent>(_onUpdateRoom);
    on<RemovePasswordEvent>(_onRemovePassword);
    on<ChangeRoomModeEvent>(_onChangeMode);
    on<ToggleCommentsEvent>(_onToggleComments);

    // Admins
    on<LoadAdminsEvent>(_onLoadAdmins);
    on<AddAdminEvent>(_onAddAdmin);
    on<RemoveAdminEvent>(_onRemoveAdmin);

    // Blacklist
    on<LoadBlacklistEvent>(_onLoadBlacklist);
    on<KickUserEvent>(_onKickUser);
    on<BanUserEvent>(_onBanUser);
    on<UnbanUserEvent>(_onUnbanUser);

    // Visitors
    on<LoadVisitorsEvent>(_onLoadVisitors);
    on<LoadMoreVisitorsEvent>(_onLoadMoreVisitors);

    // Delete
    on<DeleteRoomEvent>(_onDeleteRoom);
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
      password: event.password,
      mode: event.mode,
      roomType: event.roomType,
      roomClass: event.roomClass,
      isCommentsClosed: event.isCommentsClosed,
      freeMic: event.freeMic,
      cover: event.cover,
    );

    switch (result) {
      case Success(data: final data):
        emit(state.copyWith(
          updateState: RequestState.loaded,
          updatedRoom: data.data,
        ));
      case Failure(message: final message):
        emit(state.copyWith(
          updateState: RequestState.error,
          message: message,
        ));
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
        emit(state.copyWith(
          updateState: RequestState.error,
          message: message,
        ));
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
        emit(state.copyWith(updateState: RequestState.loaded));
      case Failure(message: final message):
        emit(state.copyWith(
          updateState: RequestState.error,
          message: message,
        ));
    }
  }

  Future<void> _onToggleComments(
    ToggleCommentsEvent event,
    Emitter<RoomManagementState> emit,
  ) async {
    final result = await repository.toggleComments(
      event.roomId,
      event.closed,
    );

    switch (result) {
      case Success():
        emit(state.copyWith(updateState: RequestState.loaded));
      case Failure(message: final message):
        emit(state.copyWith(
          updateState: RequestState.error,
          message: message,
        ));
    }
  }

  // Admin management

  Future<void> _onLoadAdmins(
    LoadAdminsEvent event,
    Emitter<RoomManagementState> emit,
  ) async {
    emit(state.copyWith(adminsState: RequestState.loading));

    final result = await repository.getAdmins(event.roomId);

    switch (result) {
      case Success(data: final data):
        emit(state.copyWith(
          admins: data.data ?? [],
          adminsState: RequestState.loaded,
        ));
      case Failure(message: final message):
        emit(state.copyWith(
          adminsState: RequestState.error,
          message: message,
        ));
    }
  }

  Future<void> _onAddAdmin(
    AddAdminEvent event,
    Emitter<RoomManagementState> emit,
  ) async {
    final result = await repository.addAdmin(event.roomId, event.userId);

    switch (result) {
      case Success():
        add(LoadAdminsEvent(roomId: event.roomId));
      case Failure(message: final message):
        emit(state.copyWith(message: message));
    }
  }

  Future<void> _onRemoveAdmin(
    RemoveAdminEvent event,
    Emitter<RoomManagementState> emit,
  ) async {
    final result = await repository.removeAdmin(event.roomId, event.userId);

    switch (result) {
      case Success():
        emit(state.copyWith(
          admins: state.admins.where((a) => a.id != event.userId).toList(),
        ));
      case Failure(message: final message):
        emit(state.copyWith(message: message));
    }
  }

  // Blacklist management

  Future<void> _onLoadBlacklist(
    LoadBlacklistEvent event,
    Emitter<RoomManagementState> emit,
  ) async {
    emit(state.copyWith(blacklistState: RequestState.loading));

    final result = await repository.getBlacklist(event.roomId);

    switch (result) {
      case Success(data: final data):
        emit(state.copyWith(
          blacklist: data.data ?? [],
          blacklistState: RequestState.loaded,
        ));
      case Failure(message: final message):
        emit(state.copyWith(
          blacklistState: RequestState.error,
          message: message,
        ));
    }
  }

  Future<void> _onKickUser(
    KickUserEvent event,
    Emitter<RoomManagementState> emit,
  ) async {
    final result = await repository.kickUser(
      event.roomId,
      event.userId,
      minutes: event.minutes,
    );

    switch (result) {
      case Success():
        emit(state.copyWith(updateState: RequestState.loaded));
      case Failure(message: final message):
        emit(state.copyWith(message: message));
    }
  }

  Future<void> _onBanUser(
    BanUserEvent event,
    Emitter<RoomManagementState> emit,
  ) async {
    final result = await repository.banUser(
      event.roomId,
      event.userId,
      durationSeconds: event.durationSeconds,
      reason: event.reason,
    );

    switch (result) {
      case Success():
        add(LoadBlacklistEvent(roomId: event.roomId));
      case Failure(message: final message):
        emit(state.copyWith(message: message));
    }
  }

  Future<void> _onUnbanUser(
    UnbanUserEvent event,
    Emitter<RoomManagementState> emit,
  ) async {
    final result = await repository.unbanUser(event.roomId, event.userId);

    switch (result) {
      case Success():
        emit(state.copyWith(
          blacklist: state.blacklist
              .where((b) => b['user_id'] != event.userId)
              .toList(),
        ));
      case Failure(message: final message):
        emit(state.copyWith(message: message));
    }
  }

  // Visitors

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
        emit(state.copyWith(
          visitors: visitors,
          visitorsState: RequestState.loaded,
          visitorsPage: 1,
          hasMoreVisitors: paginates != null
              ? paginates.currentPage < paginates.lastPage
              : false,
        ));
      case Failure(message: final message):
        emit(state.copyWith(
          visitorsState: RequestState.error,
          message: message,
        ));
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
        emit(state.copyWith(
          visitors: [...state.visitors, ...newVisitors],
          visitorsPage: nextPage,
          hasMoreVisitors: paginates != null
              ? paginates.currentPage < paginates.lastPage
              : false,
        ));
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
        emit(state.copyWith(
          deleteState: RequestState.error,
          message: message,
        ));
    }
  }
}
