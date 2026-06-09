part of 'register_bloc.dart';

sealed class BaseRegisterEvent extends Equatable {
  const BaseRegisterEvent();

  @override
  List<Object?> get props => [];
}

class TogglePasswordVisibilityEvent extends BaseRegisterEvent {
  const TogglePasswordVisibilityEvent();
}

final class RegisterEvent extends BaseRegisterEvent {
  final BuildContext context;

  const RegisterEvent({required this.context});

  @override
  List<Object?> get props => [context];
}

class ValidEventRegister extends BaseRegisterEvent {
  const ValidEventRegister();
}
