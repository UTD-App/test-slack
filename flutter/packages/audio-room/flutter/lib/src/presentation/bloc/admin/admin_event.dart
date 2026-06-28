part of 'admin_bloc.dart';

sealed class AdminEvent extends Equatable {
  const AdminEvent();

  @override
  List<Object?> get props => [];
}

class LoadAdminsEvent extends AdminEvent {
  final int roomId;

  const LoadAdminsEvent({required this.roomId});

  @override
  List<Object?> get props => [roomId];
}

class AddAdminEvent extends AdminEvent {
  final int roomId;
  final int userId;

  const AddAdminEvent({required this.roomId, required this.userId});

  @override
  List<Object?> get props => [roomId, userId];
}

class RemoveAdminEvent extends AdminEvent {
  final int roomId;
  final int userId;

  const RemoveAdminEvent({required this.roomId, required this.userId});

  @override
  List<Object?> get props => [roomId, userId];
}
