part of 'room_management_bloc.dart';

class RoomManagementState extends Equatable {
  final List<RoomAdminModel> admins;
  final List<RoomVisitorModel> visitors;
  final List<Map<String, dynamic>> blacklist;
  final RequestState adminsState;
  final RequestState visitorsState;
  final RequestState blacklistState;
  final RequestState updateState;
  final RequestState deleteState;
  final RoomModel? updatedRoom;
  final String? message;
  final int visitorsPage;
  final bool hasMoreVisitors;

  const RoomManagementState({
    this.admins = const [],
    this.visitors = const [],
    this.blacklist = const [],
    this.adminsState = RequestState.idle,
    this.visitorsState = RequestState.idle,
    this.blacklistState = RequestState.idle,
    this.updateState = RequestState.idle,
    this.deleteState = RequestState.idle,
    this.updatedRoom,
    this.message,
    this.visitorsPage = 1,
    this.hasMoreVisitors = false,
  });

  RoomManagementState copyWith({
    List<RoomAdminModel>? admins,
    List<RoomVisitorModel>? visitors,
    List<Map<String, dynamic>>? blacklist,
    RequestState? adminsState,
    RequestState? visitorsState,
    RequestState? blacklistState,
    RequestState? updateState,
    RequestState? deleteState,
    RoomModel? updatedRoom,
    String? message,
    int? visitorsPage,
    bool? hasMoreVisitors,
  }) {
    return RoomManagementState(
      admins: admins ?? this.admins,
      visitors: visitors ?? this.visitors,
      blacklist: blacklist ?? this.blacklist,
      adminsState: adminsState ?? this.adminsState,
      visitorsState: visitorsState ?? this.visitorsState,
      blacklistState: blacklistState ?? this.blacklistState,
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
        admins,
        visitors,
        blacklist,
        adminsState,
        visitorsState,
        blacklistState,
        updateState,
        deleteState,
        updatedRoom,
        message,
        visitorsPage,
        hasMoreVisitors,
      ];
}
