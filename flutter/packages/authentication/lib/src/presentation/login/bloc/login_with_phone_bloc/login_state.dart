part of 'login_bloc.dart';

class LoginState extends Equatable {
  final GlobalKey<FormState> formKey;
  final RequestState requestState;
  final TextEditingController passwordController;
  final TextEditingController emailController;
  final bool isPassword;
  final IconData suffixIcon;
  final String message;
  final bool? isFormValid;
  final RequestState requestStateCheckEmail;
  final bool? isFoundAccount;
  final bool showRegisterDialog;

  const LoginState({
    required this.formKey,
    this.requestState = RequestState.idle,
    this.requestStateCheckEmail = RequestState.idle,
    required this.passwordController,
    required this.emailController,
    this.isPassword = true,
    this.suffixIcon = CupertinoIcons.eye,
    this.message = '',
    this.isFormValid,
    this.isFoundAccount,
    this.showRegisterDialog = false,
  });

  LoginState copyWith({
    RequestState? requestState,
    RequestState? requestStateCheckEmail,
    bool? isPassword,
    IconData? suffixIcon,
    String? message,
    bool? isFormValid,
    bool? isFoundAccount,
    bool? showRegisterDialog,
  }) {
    return LoginState(
      formKey: formKey,
      requestState: requestState ?? this.requestState,
      passwordController: passwordController,
      emailController: emailController,
      isPassword: isPassword ?? this.isPassword,
      suffixIcon: suffixIcon ?? this.suffixIcon,
      message: message ?? this.message,
      isFormValid: isFormValid ?? this.isFormValid,
      isFoundAccount: isFoundAccount ?? this.isFoundAccount,
      requestStateCheckEmail:
          requestStateCheckEmail ?? this.requestStateCheckEmail,
      showRegisterDialog: showRegisterDialog ?? this.showRegisterDialog,
    );
  }

  @override
  List<Object?> get props => [
        requestState,
        emailController,
        passwordController,
        isPassword,
        suffixIcon,
        message,
        isFormValid,
        isFoundAccount,
        requestStateCheckEmail,
        showRegisterDialog,
      ];
}
