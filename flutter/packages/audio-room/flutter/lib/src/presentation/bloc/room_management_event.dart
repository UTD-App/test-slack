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

// Admin events

class LoadAdminsEvent extends RoomManagementEvent {
  final int roomId;

  const LoadAdminsEvent({required this.roomId});

  @override
  List<Object?> get props => [roomId];
}

class AddAdminEvent extends RoomManagementEvent {
  final int roomId;
  final int userId;

  const AddAdminEvent({required this.roomId, required this.userId});

  @override
  List<Object?> get props => [roomId, userId];
}

class RemoveAdminEvent extends RoomManagementEvent {
  final int roomId;
  final int userId;

  const RemoveAdminEvent({required this.roomId, required this.userId});

  @override
  List<Object?> get props => [roomId, userId];
}

// Blacklist events

class LoadBlacklistEvent extends RoomManagementEvent {
  final int roomId;

  const LoadBlacklistEvent({required this.roomId});

  @override
  List<Object?> get props => [roomId];
}

class KickUserEvent extends RoomManagementEvent {
  final int roomId;
  final int userId;
  final int minutes;

  const KickUserEvent({
    required this.roomId,
    required this.userId,
    this.minutes = 5,
  });

  @override
  List<Object?> get props => [roomId, userId, minutes];
}

class BanUserEvent extends RoomManagementEvent {
  final int roomId;
  final int userId;
  final int? durationSeconds;
  final String? reason;

  const BanUserEvent({
    required this.roomId,
    required this.userId,
    this.durationSeconds,
    this.reason,
  });

  @override
  List<Object?> get props => [roomId, userId, durationSeconds, reason];
}

class UnbanUserEvent extends RoomManagementEvent {
  final int roomId;
  final int userId;

  const UnbanUserEvent({required this.roomId, required this.userId});

  @override
  List<Object?> get props => [roomId, userId];
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
