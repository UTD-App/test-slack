part of 'free_games_bloc.dart';

sealed class FreeGamesEvent extends Equatable {
  const FreeGamesEvent();

  @override
  List<Object?> get props => [];
}

final class LoadFreeGamesImagesEvent extends FreeGamesEvent {
  const LoadFreeGamesImagesEvent();
}
