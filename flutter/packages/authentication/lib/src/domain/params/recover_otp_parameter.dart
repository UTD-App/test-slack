import 'package:equatable/equatable.dart';

/// Step 2 of email-OTP recovery: verify a code for an email.
class VerifyOtpParameter extends Equatable {
  final String email;
  final String code;

  const VerifyOtpParameter({required this.email, required this.code});

  @override
  List<Object?> get props => [email, code];
}

/// Step 3 of email-OTP recovery: set a new password using a verified code.
class ResetWithOtpParameter extends Equatable {
  final String email;
  final String code;
  final String password;

  const ResetWithOtpParameter({
    required this.email,
    required this.code,
    required this.password,
  });

  @override
  List<Object?> get props => [email, code, password];
}
