part of 'super_bomb_bloc.dart';

sealed class SuperBombEvent extends Equatable {
  const SuperBombEvent();

  @override
  List<Object?> get props => [];
}

final class LoadBoomLevelsEvent extends SuperBombEvent {
  final int roomId;

  const LoadBoomLevelsEvent({required this.roomId});

  @override
  List<Object?> get props => [roomId];
}

final class LoadBoomVideosEvent extends SuperBombEvent {
  const LoadBoomVideosEvent();
}

final class LoadBoomThemesEvent extends SuperBombEvent {
  const LoadBoomThemesEvent();
}

final class LoadBoomRulesEvent extends SuperBombEvent {
  const LoadBoomRulesEvent();
}

final class SelectBoomLevelEvent extends SuperBombEvent {
  final BoomLevelModel level;

  const SelectBoomLevelEvent({required this.level});

  @override
  List<Object?> get props => [level];
}
