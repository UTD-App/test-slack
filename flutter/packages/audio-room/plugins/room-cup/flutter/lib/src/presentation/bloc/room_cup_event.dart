part of 'room_cup_bloc.dart';

sealed class RoomCupEvent extends Equatable {
  const RoomCupEvent();

  @override
  List<Object?> get props => [];
}

final class LoadMyRewardEvent extends RoomCupEvent {
  final int roomId;

  const LoadMyRewardEvent({required this.roomId});

  @override
  List<Object?> get props => [roomId];
}

final class LoadHistoryEvent extends RoomCupEvent {
  final int roomId;

  const LoadHistoryEvent({required this.roomId});

  @override
  List<Object?> get props => [roomId];
}

final class LoadCupTargetsEvent extends RoomCupEvent {
  const LoadCupTargetsEvent();
}
