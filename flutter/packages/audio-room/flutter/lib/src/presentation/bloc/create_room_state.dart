part of 'create_room_bloc.dart';

class CreateRoomState extends Equatable {
  final RequestState createState;
  final List<RoomCategoryModel> types;
  final RequestState typesState;
  final RoomModel? createdRoom;
  final RoomModel? existingRoom;
  final RequestState checkState;
  final String? message;

  const CreateRoomState({
    this.createState = RequestState.idle,
    this.types = const [],
    this.typesState = RequestState.idle,
    this.createdRoom,
    this.existingRoom,
    this.checkState = RequestState.idle,
    this.message,
  });

  bool get hasExistingRoom => existingRoom != null;

  CreateRoomState copyWith({
    RequestState? createState,
    List<RoomCategoryModel>? types,
    RequestState? typesState,
    RoomModel? createdRoom,
    RoomModel? existingRoom,
    bool clearExistingRoom = false,
    RequestState? checkState,
    String? message,
  }) {
    return CreateRoomState(
      createState: createState ?? this.createState,
      types: types ?? this.types,
      typesState: typesState ?? this.typesState,
      createdRoom: createdRoom ?? this.createdRoom,
      existingRoom: clearExistingRoom ? null : (existingRoom ?? this.existingRoom),
      checkState: checkState ?? this.checkState,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [createState, types, typesState, createdRoom, existingRoom, checkState, message];
}
