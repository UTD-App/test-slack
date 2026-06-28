part of 'room_management_bloc.dart';

class RoomManagementState extends Equatable {
  final RoomModel? enteredRoom;
  final RequestState enterState;
  final RequestState exitState;
  final List<RoomVisitorModel> visitors;
  final RequestState visitorsState;
  final RequestState updateState;
  final RequestState deleteState;
  final RoomModel? updatedRoom;
  final String? message;
  final int visitorsPage;
  final bool hasMoreVisitors;

  const RoomManagementState({
    this.enteredRoom,
    this.enterState = RequestState.idle,
    this.exitState = RequestState.idle,
    this.visitors = const [],
    this.visitorsState = RequestState.idle,
    this.updateState = RequestState.idle,
    this.deleteState = RequestState.idle,
    this.updatedRoom,
    this.message,
    this.visitorsPage = 1,
    this.hasMoreVisitors = false,
  });

  RoomManagementState copyWith({
    RoomModel? enteredRoom,
    bool clearEnteredRoom = false,
    RequestState? enterState,
    RequestState? exitState,
    List<RoomVisitorModel>? visitors,
    RequestState? visitorsState,
    RequestState? updateState,
    RequestState? deleteState,
    RoomModel? updatedRoom,
    bool clearUpdatedRoom = false,
    String? message,
    int? visitorsPage,
    bool? hasMoreVisitors,
  }) {
    return RoomManagementState(
      enteredRoom: clearEnteredRoom ? null : (enteredRoom ?? this.enteredRoom),
      enterState: enterState ?? this.enterState,
      exitState: exitState ?? this.exitState,
      visitors: visitors ?? this.visitors,
      visitorsState: visitorsState ?? this.visitorsState,
      updateState: updateState ?? this.updateState,
      deleteState: deleteState ?? this.deleteState,
      updatedRoom: clearUpdatedRoom ? null : (updatedRoom ?? this.updatedRoom),
      message: message ?? this.message,
      visitorsPage: visitorsPage ?? this.visitorsPage,
      hasMoreVisitors: hasMoreVisitors ?? this.hasMoreVisitors,
    );
  }

  @override
  List<Object?> get props => [
        enteredRoom,
        enterState,
        exitState,
        visitors,
        visitorsState,
        updateState,
        deleteState,
        updatedRoom,
        message,
        visitorsPage,
        hasMoreVisitors,
      ];
}
