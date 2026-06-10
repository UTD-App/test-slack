part of 'charisma_bloc.dart';

class CharismaState extends Equatable {
  final List<CharismaModel>? data;
  final bool charismaActive;
  final List<CharismaLevelModel> levels;
  final RequestState levelsState;
  final RequestState dataState;
  final RequestState statusState;
  final RequestState resetState;
  final String? message;

  const CharismaState({
    this.data,
    this.charismaActive = false,
    this.levels = const [],
    this.levelsState = RequestState.idle,
    this.dataState = RequestState.idle,
    this.statusState = RequestState.idle,
    this.resetState = RequestState.idle,
    this.message,
  });

  CharismaState copyWith({
    List<CharismaModel>? data,
    bool? charismaActive,
    List<CharismaLevelModel>? levels,
    RequestState? levelsState,
    RequestState? dataState,
    RequestState? statusState,
    RequestState? resetState,
    String? message,
  }) {
    return CharismaState(
      data: data ?? this.data,
      charismaActive: charismaActive ?? this.charismaActive,
      levels: levels ?? this.levels,
      levelsState: levelsState ?? this.levelsState,
      dataState: dataState ?? this.dataState,
      statusState: statusState ?? this.statusState,
      resetState: resetState ?? this.resetState,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [
        data,
        charismaActive,
        levels,
        levelsState,
        dataState,
        statusState,
        resetState,
        message,
      ];
}
