import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/shared/core/enums.dart';

import '../../../domain/audio_room_repository.dart';
import '../../../domain/blacklist_entry_model.dart';

part 'blacklist_event.dart';
part 'blacklist_state.dart';

/// Manages a room's blacklist: loading active bans and the kick / ban / unban
/// actions. Mirrors [RoomManagementBloc]'s conventions and re-fetches the list
/// after every mutation so an open blacklist sheet stays current.
class BlacklistBloc extends Bloc<BlacklistEvent, BlacklistState> {
  final AudioRoomRepository repository;

  BlacklistBloc({required this.repository}) : super(const BlacklistState()) {
    on<LoadBlacklistEvent>(_onLoad);
    on<BanUserEvent>(_onBan);
    on<KickUserEvent>(_onKick);
    on<UnbanUserEvent>(_onUnban);
    on<MuteWritingEvent>(_onMuteWriting);
    on<UnmuteWritingEvent>(_onUnmuteWriting);
  }

  Future<void> _onLoad(
    LoadBlacklistEvent event,
    Emitter<BlacklistState> emit,
  ) async {
    emit(state.copyWith(blacklistState: RequestState.loading));
    await _reload(event.roomId, emit, markErrorOnFailure: true);
  }

  Future<void> _onBan(
    BanUserEvent event,
    Emitter<BlacklistState> emit,
  ) async {
    final result = await repository.banUser(
      event.roomId,
      event.userId,
      durationSeconds: event.durationSeconds,
      reason: event.reason,
    );

    switch (result) {
      case Success():
        await _reload(event.roomId, emit);
      case Failure(message: final message):
        emit(state.copyWith(message: message));
    }
  }

  Future<void> _onKick(
    KickUserEvent event,
    Emitter<BlacklistState> emit,
  ) async {
    final result = await repository.kickUser(
      event.roomId,
      event.userId,
      minutes: event.minutes,
    );

    switch (result) {
      case Success():
        await _reload(event.roomId, emit);
      case Failure(message: final message):
        emit(state.copyWith(message: message));
    }
  }

  Future<void> _onUnban(
    UnbanUserEvent event,
    Emitter<BlacklistState> emit,
  ) async {
    final result = await repository.unbanUser(event.roomId, event.userId);

    switch (result) {
      case Success():
        await _reload(event.roomId, emit);
      case Failure(message: final message):
        emit(state.copyWith(message: message));
    }
  }

  Future<void> _onMuteWriting(
    MuteWritingEvent event,
    Emitter<BlacklistState> emit,
  ) async {
    final result = await repository.muteWriting(event.roomId, event.userId);

    switch (result) {
      case Success():
        break;
      case Failure(message: final message):
        emit(state.copyWith(message: message));
    }
  }

  Future<void> _onUnmuteWriting(
    UnmuteWritingEvent event,
    Emitter<BlacklistState> emit,
  ) async {
    final result = await repository.unmuteWriting(event.roomId, event.userId);

    switch (result) {
      case Success():
        break;
      case Failure(message: final message):
        emit(state.copyWith(message: message));
    }
  }

  Future<void> _reload(
    int roomId,
    Emitter<BlacklistState> emit, {
    bool markErrorOnFailure = false,
  }) async {
    final result = await repository.getBlacklist(roomId);

    switch (result) {
      case Success(data: final data):
        emit(state.copyWith(
          blacklist: data.data ?? const [],
          blacklistState: RequestState.loaded,
        ));
      case Failure(message: final message):
        emit(state.copyWith(
          blacklistState:
              markErrorOnFailure ? RequestState.error : state.blacklistState,
          message: message,
        ));
    }
  }
}
