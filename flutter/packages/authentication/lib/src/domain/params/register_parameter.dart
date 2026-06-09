import 'package:equatable/equatable.dart';

class RegisterParameter extends Equatable {
  final String email;
  final String password;

  const RegisterParameter({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}
