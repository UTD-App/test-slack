part of 'recover_password_bloc.dart';

sealed class RecoverPasswordEvent extends Equatable {
  const RecoverPasswordEvent();

  @override
  List<Object?> get props => [];
}

/// Step 1 submit: email the OTP to the entered address.
class RecoverSendOtpEvent extends RecoverPasswordEvent {
  final BuildContext context;
  const RecoverSendOtpEvent({required this.context});

  @override
  List<Object?> get props => [context];
}

/// Request a fresh OTP (only honoured once the cooldown elapses).
class RecoverResendOtpEvent extends RecoverPasswordEvent {
  final BuildContext context;
  const RecoverResendOtpEvent({required this.context});

  @override
  List<Object?> get props => [context];
}

/// Step 2 submit: verify the entered code.
class RecoverVerifyOtpEvent extends RecoverPasswordEvent {
  final BuildContext context;
  const RecoverVerifyOtpEvent({required this.context});

  @override
  List<Object?> get props => [context];
}

/// Step 3 submit: set the new password.
class RecoverResetPasswordEvent extends RecoverPasswordEvent {
  final BuildContext context;
  const RecoverResetPasswordEvent({required this.context});

  @override
  List<Object?> get props => [context];
}

class RecoverTogglePasswordEvent extends RecoverPasswordEvent {
  const RecoverTogglePasswordEvent();
}

class RecoverToggleConfirmEvent extends RecoverPasswordEvent {
  const RecoverToggleConfirmEvent();
}

class RecoverUpdateValidationEvent extends RecoverPasswordEvent {
  const RecoverUpdateValidationEvent();
}

/// Return to the first step (email entry) from a later step.
class RecoverBackToStartEvent extends RecoverPasswordEvent {
  const RecoverBackToStartEvent();
}

/// Internal: one second elapsed on the resend countdown.
class RecoverTickEvent extends RecoverPasswordEvent {
  const RecoverTickEvent();
}
