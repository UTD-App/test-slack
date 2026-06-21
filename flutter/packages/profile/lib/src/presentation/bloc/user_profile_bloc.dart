import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/shared/core/enums.dart';

import '../../domain/profile_repository.dart';
import '../../domain/user_profile_model.dart';

part 'user_profile_event.dart';
part 'user_profile_state.dart';

class UserProfileBloc extends Bloc<UserProfileEvent, UserProfileState> {
  final ProfileRepository repository;

  UserProfileBloc({required this.repository})
      : super(const UserProfileState()) {
    on<LoadUserProfileEvent>(_onLoadProfile);
  }

  Future<void> _onLoadProfile(
    LoadUserProfileEvent event,
    Emitter<UserProfileState> emit,
  ) async {
    if (!event.silent) {
      emit(state.copyWith(requestState: RequestState.loading));
    }

    final result = await repository.getUserProfile(event.userId);

    switch (result) {
      case Success(data: final data):
        emit(
          state.copyWith(
            requestState: RequestState.loaded,
            profile: data.data,
            message: data.message,
          ),
        );
      case Failure(message: final message):
        emit(
          state.copyWith(
            requestState: RequestState.error,
            message: message,
          ),
        );
    }
  }
}
