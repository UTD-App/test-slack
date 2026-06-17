part of 'charisma_bloc.dart';

sealed class CharismaEvent extends Equatable {
  const CharismaEvent();

  @override
  List<Object?> get props => [];
}

final class FetchCharismaLevelsEvent extends CharismaEvent {
  const FetchCharismaLevelsEvent();
}

final class LoadRoomCharismaEvent extends CharismaEvent {
  final int roomId;
  final bool? activeOverride;

  const LoadRoomCharismaEvent({required this.roomId, this.activeOverride});

  @override
  List<Object?> get props => [roomId, activeOverride];
}

final class ChangeCharismaStatusEvent extends CharismaEvent {
  final int roomId;
  final bool status;

  const ChangeCharismaStatusEvent({required this.roomId, required this.status});

  @override
  List<Object?> get props => [roomId, status];
}

final class ResetCharismaEvent extends CharismaEvent {
  final int roomId;

  const ResetCharismaEvent({required this.roomId});

  @override
  List<Object?> get props => [roomId];
}

final class UpdateCharismaEvent extends CharismaEvent {
  final List<CharismaModel> data;

  const UpdateCharismaEvent({required this.data});

  @override
  List<Object?> get props => [data];
}

final class InitCharismaEvent extends CharismaEvent {
  const InitCharismaEvent();
}
