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

  const SubmitCreateRoomEvent({
    required this.name,
    required this.mode,
    this.intro,
    this.roomType,
    this.roomClass,
    this.password,
    this.cover,
  });

  @override
  List<Object?> get props => [name, mode, intro, roomType, roomClass, password, cover];
}

class LoadRoomTypesEvent extends CreateRoomEvent {
  const LoadRoomTypesEvent();
}

class CheckMyRoomEvent extends CreateRoomEvent {
  const CheckMyRoomEvent();
}
