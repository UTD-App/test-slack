import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/shared/core/enums.dart';

import '../../../domain/audio_room_repository.dart';
import '../../../domain/room_admin_model.dart';

part 'admin_event.dart';
part 'admin_state.dart';

/// Manages the list of room administrators (load / add / remove).
///
/// Mirrors [RoomManagementBloc]'s conventions: a single [AudioRoomRepository],
/// [RequestState]-driven immutable state, and a re-fetch after every mutation so
/// any open admin sheet reflects the latest list.
class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AudioRoomRepository repository;

  AdminBloc({required this.repository}) : super(const AdminState()) {
    on<LoadAdminsEvent>(_onLoadAdmins);
    on<AddAdminEvent>(_onAddAdmin);
    on<RemoveAdminEvent>(_onRemoveAdmin);
  }

  Future<void> _onLoadAdmins(
    LoadAdminsEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(adminsState: RequestState.loading));
    await _reload(event.roomId, emit, markErrorOnFailure: true);
  }

  Future<void> _onAddAdmin(
    AddAdminEvent event,
    Emitter<AdminState> emit,
  ) async {
    final result = await repository.addAdmin(event.roomId, event.userId);

    switch (result) {
      case Success():
        await _reload(event.roomId, emit);
      case Failure(message: final message):
        emit(state.copyWith(message: message));
    }
  }

  Future<void> _onRemoveAdmin(
    RemoveAdminEvent event,
    Emitter<AdminState> emit,
  ) async {
    final result = await repository.removeAdmin(event.roomId, event.userId);

    switch (result) {
      case Success():
        await _reload(event.roomId, emit);
      case Failure(message: final message):
        emit(state.copyWith(message: message));
    }
  }

  Future<void> _reload(
    int roomId,
    Emitter<AdminState> emit, {
    bool markErrorOnFailure = false,
  }) async {
    final result = await repository.getAdmins(roomId);

    switch (result) {
      case Success(data: final data):
        emit(state.copyWith(
          admins: data.data ?? const [],
          adminsState: RequestState.loaded,
        ));
      case Failure(message: final message):
        emit(state.copyWith(
          adminsState:
              markErrorOnFailure ? RequestState.error : state.adminsState,
          message: message,
        ));
    }
  }
}
