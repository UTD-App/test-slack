import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/shared/core/enums.dart';

import '../../domain/free_games_model.dart';
import '../../domain/free_games_repository.dart';

part 'free_games_event.dart';
part 'free_games_state.dart';

class FreeGamesBloc extends Bloc<FreeGamesEvent, FreeGamesState> {
  final FreeGamesRepository repository;

  FreeGamesBloc({required this.repository}) : super(const FreeGamesState()) {
    on<LoadFreeGamesImagesEvent>(_onLoadImages);
  }

  Future<void> _onLoadImages(
    LoadFreeGamesImagesEvent event,
    Emitter<FreeGamesState> emit,
  ) async {
    emit(state.copyWith(requestState: RequestState.loading));

    final result = await repository.getImages();

    switch (result) {
      case Success(data: final data):
        emit(state.copyWith(
          data: data.data,
          requestState: RequestState.loaded,
        ));
      case Failure(message: final message):
        emit(state.copyWith(
          requestState: RequestState.error,
          message: message,
        ));
    }
  }
}
