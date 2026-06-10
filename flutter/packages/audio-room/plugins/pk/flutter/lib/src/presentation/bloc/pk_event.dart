part of 'pk_bloc.dart';

sealed class PkEvent extends Equatable {
  const PkEvent();

  @override
  List<Object?> get props => [];
}

final class ShowPkEvent extends PkEvent {
  final int? roomId;
  final int? ownerId;

  const ShowPkEvent({this.roomId, this.ownerId});

  @override
  List<Object?> get props => [roomId, ownerId];
}

final class StartPkEvent extends PkEvent {
  final int? roomId;
  final int? ownerId;
  final int minutes;

  const StartPkEvent({this.roomId, this.ownerId, required this.minutes});

  @override
  List<Object?> get props => [roomId, ownerId, minutes];
}

final class ClosePkEvent extends PkEvent {
  final int pkId;
  final int? roomId;
  final int? ownerId;

  const ClosePkEvent({required this.pkId, this.roomId, this.ownerId});

  @override
  List<Object?> get props => [pkId, roomId, ownerId];
}

final class HidePkEvent extends PkEvent {
  final int? roomId;
  final int? ownerId;

  const HidePkEvent({this.roomId, this.ownerId});

  @override
  List<Object?> get props => [roomId, ownerId];
}

final class LoadPkHistoryEvent extends PkEvent {
  final int roomId;

  const LoadPkHistoryEvent({required this.roomId});

  @override
  List<Object?> get props => [roomId];
}
