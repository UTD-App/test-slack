part of 'create_room_bloc.dart';

sealed class CreateRoomEvent extends Equatable {
  const CreateRoomEvent();

  @override
  List<Object?> get props => [];
}

class SubmitCreateRoomEvent extends CreateRoomEvent {
  final String name;
  final int mode;
  final String? intro;
  final int? roomType;
  final int? roomClass;
  final String? password;
  final File? cover;
  final File? emptySeatIcon;
  final File? lockedSeatIcon;
  final String? emptySeatIconPreset;
  final String? lockedSeatIconPreset;

  const SubmitCreateRoomEvent({
    required this.name,
    required this.mode,
    this.intro,
    this.roomType,
    this.roomClass,
    this.password,
    this.cover,
    this.emptySeatIcon,
    this.lockedSeatIcon,
    this.emptySeatIconPreset,
    this.lockedSeatIconPreset,
  });

  @override
  List<Object?> get props => [name, mode, intro, roomType, roomClass, password, cover, emptySeatIcon, lockedSeatIcon, emptySeatIconPreset, lockedSeatIconPreset];
}

class LoadRoomTypesEvent extends CreateRoomEvent {
  const LoadRoomTypesEvent();
}

class CheckMyRoomEvent extends CreateRoomEvent {
  const CheckMyRoomEvent();
}
