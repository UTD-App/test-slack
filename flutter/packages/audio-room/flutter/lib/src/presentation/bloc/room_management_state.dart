part of 'room_management_bloc.dart';

class RoomManagementState extends Equatable {
  final List<RoomVisitorModel> visitors;
  final RequestState visitorsState;
  final RequestState updateState;
  final RequestState deleteState;
  final RoomModel? updatedRoom;
  final String? message;
  final int visitorsPage;
  final bool hasMoreVisitors;

  const RoomManagementState({
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
    List<RoomVisitorModel>? visitors,
    RequestState? visitorsState,
    RequestState? updateState,
    RequestState? deleteState,
    RoomModel? updatedRoom,
    String? message,
    int? visitorsPage,
    bool? hasMoreVisitors,
  }) {
    return RoomManagementState(
      visitors: visitors ?? this.visitors,
      visitorsState: visitorsState ?? this.visitorsState,
      updateState: updateState ?? this.updateState,
      deleteState: deleteState ?? this.deleteState,
      updatedRoom: updatedRoom ?? this.updatedRoom,
      message: message ?? this.message,
      visitorsPage: visitorsPage ?? this.visitorsPage,
      hasMoreVisitors: hasMoreVisitors ?? this.hasMoreVisitors,
    );
  }

  @override
  List<Object?> get props => [
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
