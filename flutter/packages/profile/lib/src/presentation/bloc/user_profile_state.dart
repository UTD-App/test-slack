part of 'user_profile_bloc.dart';

class UserProfileState extends Equatable {
  final RequestState requestState;
  final UserProfileModel? profile;
  final String? message;

  const UserProfileState({
    this.requestState = RequestState.idle,
    this.profile,
    this.message,
  });

  UserProfileState copyWith({
    RequestState? requestState,
    UserProfileModel? profile,
    String? message,
  }) {
    return UserProfileState(
      requestState: requestState ?? this.requestState,
      profile: profile ?? this.profile,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [requestState, profile, message];
}
