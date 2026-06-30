part of 'login_bloc.dart';

sealed class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object?> get props => [];
}

class TogglePasswordEvent extends LoginEvent {
  const TogglePasswordEvent();
}

class LoginWithEmailEvent extends LoginEvent {
  final BuildContext context;
  const LoginWithEmailEvent({required this.context});

  @override
  List<Object?> get props => [context];
}

class UpdateFormValidationEvent extends LoginEvent {
  const UpdateFormValidationEvent();
}

class ResetLoginStateEvent extends LoginEvent {
  const ResetLoginStateEvent();
}
