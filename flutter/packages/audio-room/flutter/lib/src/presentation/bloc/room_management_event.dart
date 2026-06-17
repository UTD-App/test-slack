part of 'room_management_bloc.dart';

sealed class RoomManagementEvent extends Equatable {
  const RoomManagementEvent();

  @override
  List<Object?> get props => [];
}

// Settings events

class UpdateRoomEvent extends RoomManagementEvent {
  final int roomId;
  final String? name;
  final String? intro;
  final String? rule;
  final String? background;
  final String? password;
  final int? mode;
  final int? roomType;
  final int? roomClass;
  final bool? isCommentsClosed;
  final bool? freeMic;
  final File? cover;

  const UpdateRoomEvent({
    required this.roomId,
    this.name,
    this.intro,
    this.rule,
    this.background,
    this.password,
    this.mode,
    this.roomType,
    this.roomClass,
    this.isCommentsClosed,
    this.freeMic,
    this.cover,
  });

  @override
  List<Object?> get props => [
        roomId, name, intro, rule, background, password,
        mode, roomType, roomClass, isCommentsClosed, freeMic, cover,
      ];
}

class RemovePasswordEvent extends RoomManagementEvent {
  final int roomId;

  const RemovePasswordEvent({required this.roomId});

  @override
  List<Object?> get props => [roomId];
}

class ChangeRoomModeEvent extends RoomManagementEvent {
  final int roomId;
  final int mode;

  const ChangeRoomModeEvent({required this.roomId, required this.mode});

  @override
  List<Object?> get props => [roomId, mode];
}

class ToggleCommentsEvent extends RoomManagementEvent {
  final int roomId;
  final bool closed;

  const ToggleCommentsEvent({required this.roomId, required this.closed});

  @override
  List<Object?> get props => [roomId, closed];
}

// Visitor events

class LoadVisitorsEvent extends RoomManagementEvent {
  final int roomId;

  const LoadVisitorsEvent({required this.roomId});

  @override
  List<Object?> get props => [roomId];
}

class LoadMoreVisitorsEvent extends RoomManagementEvent {
  final int roomId;

  const LoadMoreVisitorsEvent({required this.roomId});

  @override
  List<Object?> get props => [roomId];
}

// Delete room

class DeleteRoomEvent extends RoomManagementEvent {
  final int roomId;

  const DeleteRoomEvent({required this.roomId});

  @override
  List<Object?> get props => [roomId];
}
