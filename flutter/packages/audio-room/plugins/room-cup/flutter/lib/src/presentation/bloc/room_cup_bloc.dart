import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/shared/core/enums.dart';

import '../../domain/room_cup_repository.dart';

part 'room_cup_event.dart';
part 'room_cup_state.dart';

class RoomCupBloc extends Bloc<RoomCupEvent, RoomCupState> {
  final RoomCupRepository repository;

  RoomCupBloc({required this.repository}) : super(const RoomCupState()) {
    on<LoadMyRewardEvent>(_onLoadMyReward);
    on<LoadHistoryEvent>(_onLoadHistory);
    on<LoadCupTargetsEvent>(_onLoadCupTargets);
  }

  Future<void> _onLoadMyReward(
    LoadMyRewardEvent event,
    Emitter<RoomCupState> emit,
  ) async {
    emit(state.copyWith(myRewardState: RequestState.loading));

    final result = await repository.getMyReward(event.roomId);

    switch (result) {
      case Success(data: final data):
        emit(state.copyWith(
          myReward: data.data,
          myRewardState: RequestState.loaded,
        ));
      case Failure(message: final message):
        emit(state.copyWith(
            myRewardState: RequestState.error, message: message));
    }
  }

  Future<void> _onLoadHistory(
    LoadHistoryEvent event,
    Emitter<RoomCupState> emit,
  ) async {
    emit(state.copyWith(historyState: RequestState.loading));

    final result = await repository.getHistory(event.roomId);

    switch (result) {
      case Success(data: final data):
        emit(state.copyWith(
          history: data.data,
          historyState: RequestState.loaded,
        ));
      case Failure(message: final message):
        emit(state.copyWith(
            historyState: RequestState.error, message: message));
    }
  }

  Future<void> _onLoadCupTargets(
    LoadCupTargetsEvent event,
    Emitter<RoomCupState> emit,
  ) async {
    emit(state.copyWith(cupTargetsState: RequestState.loading));

    final result = await repository.getCupTargets();

    switch (result) {
      case Success(data: final data):
        emit(state.copyWith(
          cupTargets: data.data,
          cupTargetsState: RequestState.loaded,
        ));
      case Failure(message: final message):
        emit(state.copyWith(
            cupTargetsState: RequestState.error, message: message));
    }
  }
}
