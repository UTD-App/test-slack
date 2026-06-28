part of 'admin_bloc.dart';

class AdminState extends Equatable {
  final List<RoomAdminModel> admins;
  final RequestState adminsState;
  final String? message;

  const AdminState({
    this.admins = const [],
    this.adminsState = RequestState.idle,
    this.message,
  });

  AdminState copyWith({
    List<RoomAdminModel>? admins,
    RequestState? adminsState,
    String? message,
  }) {
    return AdminState(
      admins: admins ?? this.admins,
      adminsState: adminsState ?? this.adminsState,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [admins, adminsState, message];
}
