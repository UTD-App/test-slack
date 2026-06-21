part of 'recover_password_bloc.dart';

/// The three steps of the recovery flow, rendered one at a time.
enum RecoverStep { enterEmail, enterCode, setPassword }

class RecoverPasswordState extends Equatable {
  final GlobalKey<FormState> formKey;
  final RecoverStep step;
  final RequestState requestState;

  final TextEditingController emailController;
  final TextEditingController codeController;
  final TextEditingController passwordController;
  final TextEditingController confirmController;

  final bool isPassword;
  final bool isConfirmPassword;
  final IconData passwordSuffix;
  final IconData confirmSuffix;

  final bool? isStepValid;
  final int resendSeconds;
  final String message;

  const RecoverPasswordState({
    required this.formKey,
    this.step = RecoverStep.enterEmail,
    this.requestState = RequestState.idle,
    required this.emailController,
    required this.codeController,
    required this.passwordController,
    required this.confirmController,
    this.isPassword = true,
    this.isConfirmPassword = true,
    this.passwordSuffix = CupertinoIcons.eye,
    this.confirmSuffix = CupertinoIcons.eye,
    this.isStepValid,
    this.resendSeconds = 0,
    this.message = '',
  });

  RecoverPasswordState copyWith({
    RecoverStep? step,
    RequestState? requestState,
    bool? isPassword,
    bool? isConfirmPassword,
    IconData? passwordSuffix,
    IconData? confirmSuffix,
    bool? isStepValid,
    int? resendSeconds,
    String? message,
  }) {
    return RecoverPasswordState(
      formKey: formKey,
      step: step ?? this.step,
      requestState: requestState ?? this.requestState,
      emailController: emailController,
      codeController: codeController,
      passwordController: passwordController,
      confirmController: confirmController,
      isPassword: isPassword ?? this.isPassword,
      isConfirmPassword: isConfirmPassword ?? this.isConfirmPassword,
      passwordSuffix: passwordSuffix ?? this.passwordSuffix,
      confirmSuffix: confirmSuffix ?? this.confirmSuffix,
      isStepValid: isStepValid ?? this.isStepValid,
      resendSeconds: resendSeconds ?? this.resendSeconds,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [
        step,
        requestState,
        emailController,
        codeController,
        passwordController,
        confirmController,
        isPassword,
        isConfirmPassword,
        passwordSuffix,
        confirmSuffix,
        isStepValid,
        resendSeconds,
        message,
      ];
}
