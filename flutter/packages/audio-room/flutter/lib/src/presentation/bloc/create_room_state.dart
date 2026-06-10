part of 'create_room_bloc.dart';

class CreateRoomState extends Equatable {
  final RequestState createState;
  final List<RoomCategoryModel> types;
  final RequestState typesState;
  final RoomModel? createdRoom;
  final String? message;

  const CreateRoomState({
    this.createState = RequestState.idle,
    this.types = const [],
    this.typesState = RequestState.idle,
    this.createdRoom,
    this.message,
  });

  CreateRoomState copyWith({
    RequestState? createState,
    List<RoomCategoryModel>? types,
    RequestState? typesState,
    RoomModel? createdRoom,
    String? message,
  }) {
    return CreateRoomState(
      createState: createState ?? this.createState,
      types: types ?? this.types,
      typesState: typesState ?? this.typesState,
      createdRoom: createdRoom ?? this.createdRoom,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [createState, types, typesState, createdRoom, message];
}
