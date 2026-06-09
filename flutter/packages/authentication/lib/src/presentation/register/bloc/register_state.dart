part of 'register_bloc.dart';

class RegisterState extends Equatable {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isPassword;
  final IconData suffixIcon;
  final RequestState reqState;
  final String message;
  final bool isFormValid;

  const RegisterState({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    this.isPassword = true,
    this.suffixIcon = CupertinoIcons.eye,
    this.reqState = RequestState.idle,
    this.message = '',
    this.isFormValid = false,
  });

  RegisterState copyWith({
    bool? isPassword,
    IconData? suffixIcon,
    RequestState? reqState,
    String? message,
    bool? isFormValid,
  }) {
    return RegisterState(
      formKey: formKey,
      emailController: emailController,
      passwordController: passwordController,
      isPassword: isPassword ?? this.isPassword,
      suffixIcon: suffixIcon ?? this.suffixIcon,
      reqState: reqState ?? this.reqState,
      message: message ?? this.message,
      isFormValid: isFormValid ?? this.isFormValid,
    );
  }

  @override
  List<Object?> get props => [
    isPassword,
    suffixIcon,
    reqState,
    message,
    isFormValid,
  ];
}
