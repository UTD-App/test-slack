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

  const LoadRoomCharismaEvent({required this.roomId});

  @override
  List<Object?> get props => [roomId];
}

final class ChangeCharismaStatusEvent extends CharismaEvent {
  final int roomId;

  const ChangeCharismaStatusEvent({required this.roomId});

  @override
  List<Object?> get props => [roomId];
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
