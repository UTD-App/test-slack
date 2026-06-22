import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/shared/core/enums.dart';

import '../../domain/audio_room_repository.dart';
import '../../domain/room_category_model.dart';
import '../../domain/room_model.dart';

part 'create_room_event.dart';
part 'create_room_state.dart';

class CreateRoomBloc extends Bloc<CreateRoomEvent, CreateRoomState> {
  final AudioRoomRepository repository;

  CreateRoomBloc({required this.repository}) : super(const CreateRoomState()) {
    on<SubmitCreateRoomEvent>(_onCreateRoom);
    on<LoadRoomTypesEvent>(_onLoadRoomTypes);
    on<CheckMyRoomEvent>(_onCheckMyRoom);
  }

  Future<void> _onCreateRoom(
    SubmitCreateRoomEvent event,
    Emitter<CreateRoomState> emit,
  ) async {
    emit(state.copyWith(createState: RequestState.loading));

    final result = await repository.createRoom(
      name: event.name,
      mode: event.mode,
      intro: event.intro,
      roomType: event.roomType,
      roomClass: event.roomClass,
      password: event.password,
      cover: event.cover,
      emptySeatIcon: event.emptySeatIcon,
      lockedSeatIcon: event.lockedSeatIcon,
      emptySeatIconPreset: event.emptySeatIconPreset,
      lockedSeatIconPreset: event.lockedSeatIconPreset,
    );

    switch (result) {
      case Success(data: final data):
        emit(state.copyWith(
          createState: RequestState.loaded,
          createdRoom: data.data,
        ));
      case Failure(message: final message):
        emit(state.copyWith(
          createState: RequestState.error,
          message: message,
        ));
    }
  }

  Future<void> _onCheckMyRoom(
    CheckMyRoomEvent event,
    Emitter<CreateRoomState> emit,
  ) async {
    emit(state.copyWith(checkState: RequestState.loading));

    final result = await repository.getMyRoom();

    switch (result) {
      case Success(data: final data):
        emit(state.copyWith(
          checkState: RequestState.loaded,
          existingRoom: data.data,
          clearExistingRoom: data.data == null,
        ));
      case Failure(message: final message):
        emit(state.copyWith(
          checkState: RequestState.error,
          message: message,
        ));
    }
  }

  Future<void> _onLoadRoomTypes(
    LoadRoomTypesEvent event,
    Emitter<CreateRoomState> emit,
  ) async {
    emit(state.copyWith(typesState: RequestState.loading));

    final result = await repository.getCategories();

    switch (result) {
      case Success(data: final data):
        emit(state.copyWith(
          types: data.data ?? [],
          typesState: RequestState.loaded,
        ));
      case Failure(message: final message):
        emit(state.copyWith(
          typesState: RequestState.error,
          message: message,
        ));
    }
  }
}
