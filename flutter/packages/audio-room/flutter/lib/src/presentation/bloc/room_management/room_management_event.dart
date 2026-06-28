part of 'room_management_bloc.dart';

sealed class RoomManagementEvent extends Equatable {
  const RoomManagementEvent();

  @override
  List<Object?> get props => [];
}

// Room entry/exit

class EnterRoomEvent extends RoomManagementEvent {
  final int roomId;
  final String? password;

  const EnterRoomEvent({required this.roomId, this.password});

  @override
  List<Object?> get props => [roomId, password];
}

class ExitRoomEvent extends RoomManagementEvent {
  final int roomId;

  const ExitRoomEvent({required this.roomId});

  @override
  List<Object?> get props => [roomId];
}

class ToggleRoomFavoriteEvent extends RoomManagementEvent {
  final int roomId;

  const ToggleRoomFavoriteEvent({required this.roomId});

  @override
  List<Object?> get props => [roomId];
}

// Settings events

class UpdateRoomEvent extends RoomManagementEvent {
  final int roomId;
  final String? name;
  final String? intro;
  final String? rule;
  final String? background;
  final File? backgroundFile;
  final String? password;
  final int? mode;
  final int? roomType;
  final int? roomClass;
  final bool? isCommentsClosed;
  final bool? freeMic;
  final File? cover;
  final File? emptySeatIcon;
  final File? lockedSeatIcon;
  final String? emptySeatIconPreset;
  final String? lockedSeatIconPreset;
  final bool removeBackground;

  const UpdateRoomEvent({
    required this.roomId,
    this.name,
    this.intro,
    this.rule,
    this.background,
    this.backgroundFile,
    this.password,
    this.mode,
    this.roomType,
    this.roomClass,
    this.isCommentsClosed,
    this.freeMic,
    this.cover,
    this.emptySeatIcon,
    this.lockedSeatIcon,
    this.emptySeatIconPreset,
    this.lockedSeatIconPreset,
    this.removeBackground = false,
  });

  @override
  List<Object?> get props => [
        roomId, name, intro, rule, background, backgroundFile, password,
        mode, roomType, roomClass, isCommentsClosed, freeMic, cover,
        emptySeatIcon, lockedSeatIcon, emptySeatIconPreset, lockedSeatIconPreset,
        removeBackground,
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

// Yellow banner

class SendBannerEvent extends RoomManagementEvent {
  final int roomId;
  final String message;

  const SendBannerEvent({required this.roomId, required this.message});

  @override
  List<Object?> get props => [roomId, message];
}

// Pinned message

class PinMessageEvent extends RoomManagementEvent {
  final int roomId;
  final Map<String, dynamic> data;

  const PinMessageEvent({required this.roomId, required this.data});

  @override
  List<Object?> get props => [roomId, data];
}

class UnpinMessageEvent extends RoomManagementEvent {
  final int roomId;

  const UnpinMessageEvent({required this.roomId});

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
