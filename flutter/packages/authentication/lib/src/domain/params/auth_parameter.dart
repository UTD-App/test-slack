import 'package:equatable/equatable.dart';

class AuthParameter extends Equatable {
  final String email;
  final String password;

  const AuthParameter({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}
