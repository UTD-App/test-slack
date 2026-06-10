import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/shared/core/enums.dart';

import '../../domain/pk_model.dart';
import '../../domain/pk_repository.dart';

part 'pk_event.dart';
part 'pk_state.dart';

class PkBloc extends Bloc<PkEvent, PkState> {
  final PkRepository repository;

  PkBloc({required this.repository}) : super(const PkState()) {
    on<ShowPkEvent>(_onShow);
    on<StartPkEvent>(_onStart);
    on<ClosePkEvent>(_onClose);
    on<HidePkEvent>(_onHide);
    on<LoadPkHistoryEvent>(_onLoadHistory);
  }

  Future<void> _onShow(ShowPkEvent event, Emitter<PkState> emit) async {
    emit(state.copyWith(showState: RequestState.loading));

    final result =
        await repository.showPk(roomId: event.roomId, ownerId: event.ownerId);

    switch (result) {
      case Success():
        emit(state.copyWith(showState: RequestState.loaded));
      case Failure(message: final message):
        emit(state.copyWith(showState: RequestState.error, message: message));
    }
  }

  Future<void> _onStart(StartPkEvent event, Emitter<PkState> emit) async {
    emit(state.copyWith(startState: RequestState.loading));

    final result = await repository.startPk(
      roomId: event.roomId,
      ownerId: event.ownerId,
      minutes: event.minutes,
    );

    switch (result) {
      case Success(data: final data):
        final responseData = data.data;
        final messageContent =
            responseData?['messageContent'] as Map<String, dynamic>?;
        final pkId = messageContent?['pk_id'] as int?;
        emit(state.copyWith(
          startState: RequestState.loaded,
          pkId: pkId,
        ));
      case Failure(message: final message):
        emit(state.copyWith(startState: RequestState.error, message: message));
    }
  }

  Future<void> _onClose(ClosePkEvent event, Emitter<PkState> emit) async {
    emit(state.copyWith(closeState: RequestState.loading));

    final result = await repository.closePk(
      pkId: event.pkId,
      roomId: event.roomId,
      ownerId: event.ownerId,
    );

    switch (result) {
      case Success(data: final data):
        emit(state.copyWith(
          closeState: RequestState.loaded,
          closeData: data.data,
        ));
      case Failure(message: final message):
        emit(state.copyWith(closeState: RequestState.error, message: message));
    }
  }

  Future<void> _onHide(HidePkEvent event, Emitter<PkState> emit) async {
    emit(state.copyWith(hideState: RequestState.loading));

    final result =
        await repository.hidePk(roomId: event.roomId, ownerId: event.ownerId);

    switch (result) {
      case Success():
        emit(state.copyWith(hideState: RequestState.loaded));
      case Failure(message: final message):
        emit(state.copyWith(hideState: RequestState.error, message: message));
    }
  }

  Future<void> _onLoadHistory(
    LoadPkHistoryEvent event,
    Emitter<PkState> emit,
  ) async {
    emit(state.copyWith(historyState: RequestState.loading));

    final result = await repository.getHistory(event.roomId);

    switch (result) {
      case Success(data: final data):
        final items = data.data ?? [];
        emit(state.copyWith(
          history: items,
          historyState:
              items.isEmpty ? RequestState.empty : RequestState.loaded,
        ));
      case Failure(message: final message):
        emit(
            state.copyWith(historyState: RequestState.error, message: message));
    }
  }
}
