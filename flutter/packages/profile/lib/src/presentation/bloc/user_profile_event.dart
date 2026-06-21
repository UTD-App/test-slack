part of 'user_profile_bloc.dart';

sealed class UserProfileEvent extends Equatable {
  const UserProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadUserProfileEvent extends UserProfileEvent {
  final int userId;

  /// When true, refetch without flashing the full-page loader — used after an
  /// inline edit (name/bio/avatar) so the page updates in place.
  final bool silent;

  const LoadUserProfileEvent({required this.userId, this.silent = false});

  @override
  List<Object?> get props => [userId, silent];
}
