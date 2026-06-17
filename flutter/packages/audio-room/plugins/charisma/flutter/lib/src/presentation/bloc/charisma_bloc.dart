import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/shared/core/enums.dart';

import '../../domain/charisma_level_model.dart';
import '../../domain/charisma_model.dart';
import '../../domain/charisma_repository.dart';

part 'charisma_event.dart';
part 'charisma_state.dart';

class CharismaBloc extends Bloc<CharismaEvent, CharismaState> {
  final CharismaRepository repository;

  static List<CharismaLevelModel>? _cachedLevels;

  CharismaBloc({required this.repository}) : super(const CharismaState()) {
    on<FetchCharismaLevelsEvent>(_onFetchLevels);
    on<LoadRoomCharismaEvent>(_onLoadRoomCharisma);
    on<ChangeCharismaStatusEvent>(_onChangeStatus);
    on<ResetCharismaEvent>(_onReset);
    on<UpdateCharismaEvent>(_onUpdate);
    on<InitCharismaEvent>(_onInit);
  }

  static String? getLevelImage(int points) {
    if (_cachedLevels == null || _cachedLevels!.isEmpty) return null;
    CharismaLevelModel? matched;
    for (final level in _cachedLevels!) {
      if (points >= level.points) {
        matched = level;
      } else {
        break;
      }
    }
    return matched?.image;
  }

  Future<void> _onFetchLevels(
    FetchCharismaLevelsEvent event,
    Emitter<CharismaState> emit,
  ) async {
    if (_cachedLevels != null) {
      emit(state.copyWith(
        levels: _cachedLevels,
        levelsState: RequestState.loaded,
      ));
      return;
    }

    emit(state.copyWith(levelsState: RequestState.loading));

    final result = await repository.getCharismaLevels();

    switch (result) {
      case Success(data: final data):
        final levels = data.data ?? [];
        _cachedLevels = levels;
        emit(state.copyWith(
          levels: levels,
          levelsState:
              levels.isEmpty ? RequestState.empty : RequestState.loaded,
        ));
      case Failure(message: final message):
        emit(state.copyWith(levelsState: RequestState.error, message: message));
    }
  }

  Future<void> _onLoadRoomCharisma(
    LoadRoomCharismaEvent event,
    Emitter<CharismaState> emit,
  ) async {
    emit(state.copyWith(dataState: RequestState.loading));

    bool active;
    if (event.activeOverride != null) {
      active = event.activeOverride!;
    } else {
      active = false;
      final statusResult = await repository.getStatus(event.roomId);
      if (statusResult case Success(data: final statusResponse)) {
        active = statusResponse.data?['charisma_status'] as bool? ?? false;
      }
    }

    emit(state.copyWith(charismaActive: active));

    final result = await repository.getRoomCharisma(event.roomId);

    switch (result) {
      case Success(data: final data):
        emit(state.copyWith(
          data: data.data ?? [],
          charismaActive: active,
          dataState: RequestState.loaded,
        ));
      case Failure(message: final message):
        emit(state.copyWith(
          charismaActive: active,
          dataState: RequestState.error,
          message: message,
        ));
    }
  }

  Future<void> _onChangeStatus(
    ChangeCharismaStatusEvent event,
    Emitter<CharismaState> emit,
  ) async {
    emit(state.copyWith(
      statusState: RequestState.loading,
      charismaActive: event.status,
    ));

    final result = await repository.changeStatus(event.roomId, status: event.status);

    switch (result) {
      case Success(data: final data):
        final statusData = data.data as Map<String, dynamic>?;
        final active = statusData?['charisma_status'] as bool? ?? event.status;
        emit(state.copyWith(
          charismaActive: active,
          statusState: RequestState.loaded,
        ));
      case Failure(message: final message):
        emit(state.copyWith(
          charismaActive: !event.status,
          statusState: RequestState.error,
          message: message,
        ));
    }
  }

  Future<void> _onReset(
    ResetCharismaEvent event,
    Emitter<CharismaState> emit,
  ) async {
    emit(state.copyWith(resetState: RequestState.loading));

    final result = await repository.resetCharisma(event.roomId);

    switch (result) {
      case Success():
        final resetData = state.data
            ?.map((e) => CharismaModel(
                  userId: e.userId,
                  total: '0',
                  position: e.position,
                ))
            .toList();
        emit(state.copyWith(
          data: resetData,
          resetState: RequestState.loaded,
        ));
      case Failure(message: final message):
        emit(state.copyWith(resetState: RequestState.error, message: message));
    }
  }

  void _onUpdate(
    UpdateCharismaEvent event,
    Emitter<CharismaState> emit,
  ) {
    final current = List<CharismaModel>.from(state.data ?? []);
    for (final updated in event.data) {
      final index = current.indexWhere((e) => e.userId == updated.userId);
      if (index >= 0) {
        current[index] = updated;
      } else {
        current.add(updated);
      }
    }
    emit(state.copyWith(data: current));
  }

  void _onInit(
    InitCharismaEvent event,
    Emitter<CharismaState> emit,
  ) {
    emit(const CharismaState());
  }
}
