import 'package:equatable/equatable.dart';

class ForgetPasswordParameter extends Equatable {
  final String email;
  final String password;
  final String token;

  const ForgetPasswordParameter({
    required this.email,
    required this.password,
    required this.token,
  });

  @override
  List<Object?> get props => [email, password, token];
}
