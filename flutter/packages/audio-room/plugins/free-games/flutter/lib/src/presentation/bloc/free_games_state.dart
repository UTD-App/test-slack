part of 'free_games_bloc.dart';

class FreeGamesState extends Equatable {
  final FreeGamesModel? data;
  final RequestState requestState;
  final String? message;

  const FreeGamesState({
    this.data,
    this.requestState = RequestState.idle,
    this.message,
  });

  FreeGamesState copyWith({
    FreeGamesModel? data,
    RequestState? requestState,
    String? message,
  }) {
    return FreeGamesState(
      data: data ?? this.data,
      requestState: requestState ?? this.requestState,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [data, requestState, message];
}
