import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/shared/core/enums.dart';

import '../../domain/boom_level_model.dart';
import '../../domain/boom_rule_model.dart';
import '../../domain/boom_theme_model.dart';
import '../../domain/super_bomb_repository.dart';

part 'super_bomb_event.dart';
part 'super_bomb_state.dart';

class SuperBombBloc extends Bloc<SuperBombEvent, SuperBombState> {
  final SuperBombRepository repository;

  SuperBombBloc({required this.repository}) : super(const SuperBombState()) {
    on<LoadBoomLevelsEvent>(_onLoadLevels);
    on<LoadBoomVideosEvent>(_onLoadVideos);
    on<LoadBoomThemesEvent>(_onLoadThemes);
    on<LoadBoomRulesEvent>(_onLoadRules);
    on<SelectBoomLevelEvent>(_onSelectLevel);
  }

  Future<void> _onLoadLevels(
    LoadBoomLevelsEvent event,
    Emitter<SuperBombState> emit,
  ) async {
    emit(state.copyWith(levelsState: RequestState.loading));

    final result = await repository.getLevels(event.roomId);

    switch (result) {
      case Success(data: final data):
        final levels = data.data ?? [];
        emit(state.copyWith(
          levels: levels,
          levelsState:
              levels.isEmpty ? RequestState.empty : RequestState.loaded,
        ));
      case Failure(message: final message):
        emit(state.copyWith(
          levelsState: RequestState.error,
          message: message,
        ));
    }
  }

  Future<void> _onLoadVideos(
    LoadBoomVideosEvent event,
    Emitter<SuperBombState> emit,
  ) async {
    emit(state.copyWith(videosState: RequestState.loading));

    final result = await repository.getVideos();

    switch (result) {
      case Success(data: final data):
        final videos = data.data ?? [];
        emit(state.copyWith(
          videos: videos,
          videosState:
              videos.isEmpty ? RequestState.empty : RequestState.loaded,
        ));
      case Failure(message: final message):
        emit(state.copyWith(
          videosState: RequestState.error,
          message: message,
        ));
    }
  }

  Future<void> _onLoadThemes(
    LoadBoomThemesEvent event,
    Emitter<SuperBombState> emit,
  ) async {
    emit(state.copyWith(themesState: RequestState.loading));

    final result = await repository.getThemes();

    switch (result) {
      case Success(data: final data):
        emit(state.copyWith(
          theme: data.data,
          themesState: RequestState.loaded,
        ));
      case Failure(message: final message):
        emit(state.copyWith(
          themesState: RequestState.error,
          message: message,
        ));
    }
  }

  Future<void> _onLoadRules(
    LoadBoomRulesEvent event,
    Emitter<SuperBombState> emit,
  ) async {
    emit(state.copyWith(rulesState: RequestState.loading));

    final result = await repository.getRules();

    switch (result) {
      case Success(data: final data):
        final rules = data.data ?? [];
        emit(state.copyWith(
          rules: rules,
          rulesState:
              rules.isEmpty ? RequestState.empty : RequestState.loaded,
        ));
      case Failure(message: final message):
        emit(state.copyWith(
          rulesState: RequestState.error,
          message: message,
        ));
    }
  }

  void _onSelectLevel(
    SelectBoomLevelEvent event,
    Emitter<SuperBombState> emit,
  ) {
    emit(state.copyWith(selectedLevel: event.level));
  }
}
