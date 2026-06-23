import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/shared/core/enums.dart';
import 'package:utd_app/shared/core/toast_manager.dart';

import '../../../../core/auth_routes.dart';
import '../../../domain/params/recover_otp_parameter.dart';
import '../../../domain/usecases/reset_with_otp_usecase.dart';
import '../../../domain/usecases/send_otp_usecase.dart';
import '../../../domain/usecases/verify_otp_usecase.dart';

part 'recover_password_event.dart';
part 'recover_password_state.dart';

/// Drives the 3-step email-OTP password recovery flow:
/// enter email → enter code → set new password.
class RecoverPasswordBloc extends Bloc<RecoverPasswordEvent, RecoverPasswordState> {
  final SendOtpUseCase sendOtpUseCase;
  final VerifyOtpUseCase verifyOtpUseCase;
  final ResetWithOtpUseCase resetWithOtpUseCase;

  /// Seconds the user must wait before requesting another code.
  static const int resendCooldown = 60;

  Timer? _timer;

  RecoverPasswordBloc({
    required this.sendOtpUseCase,
    required this.verifyOtpUseCase,
    required this.resetWithOtpUseCase,
  }) : super(
          RecoverPasswordState(
            formKey: GlobalKey<FormState>(),
            emailController: TextEditingController(),
            codeController: TextEditingController(),
            passwordController: TextEditingController(),
            confirmController: TextEditingController(),
          ),
        ) {
    on<RecoverSendOtpEvent>(_onSendOtp);
    on<RecoverResendOtpEvent>(_onResendOtp);
    on<RecoverVerifyOtpEvent>(_onVerifyOtp);
    on<RecoverResetPasswordEvent>(_onResetPassword);
    on<RecoverTogglePasswordEvent>(_onTogglePassword);
    on<RecoverToggleConfirmEvent>(_onToggleConfirm);
    on<RecoverUpdateValidationEvent>(_onUpdateValidation);
    on<RecoverBackToStartEvent>(_onBackToStart);
    on<RecoverTickEvent>(_onTick);
  }

  Future<void> _sendCode(BuildContext context, Emitter<RecoverPasswordState> emit) async {
    emit(state.copyWith(requestState: RequestState.loading));
    final result = await sendOtpUseCase(state.emailController.text.trim());

    switch (result) {
      case Success(data: final data):
        emit(state.copyWith(
          requestState: RequestState.loaded,
          step: RecoverStep.enterCode,
          isStepValid: false,
          resendSeconds: resendCooldown,
          message: data.message,
        ));
        _startCountdown();
        if (context.mounted) {
          ToastManager.showToast(context, message: data.message);
        }
      case Failure(message: final message):
        emit(state.copyWith(requestState: RequestState.error, message: message));
        if (context.mounted) {
          ToastManager.showToast(context, message: message, isError: true);
        }
    }
  }

  Future<void> _onSendOtp(
    RecoverSendOtpEvent event,
    Emitter<RecoverPasswordState> emit,
  ) async {
    if (state.formKey.currentState?.validate() == false) return;
    await _sendCode(event.context, emit);
  }

  Future<void> _onResendOtp(
    RecoverResendOtpEvent event,
    Emitter<RecoverPasswordState> emit,
  ) async {
    if (state.resendSeconds > 0) return;
    await _sendCode(event.context, emit);
  }

  Future<void> _onVerifyOtp(
    RecoverVerifyOtpEvent event,
    Emitter<RecoverPasswordState> emit,
  ) async {
    if (state.formKey.currentState?.validate() == false) return;

    emit(state.copyWith(requestState: RequestState.loading));
    final result = await verifyOtpUseCase(
      VerifyOtpParameter(
        email: state.emailController.text.trim(),
        code: state.codeController.text.trim(),
      ),
    );

    switch (result) {
      case Success(data: final data):
        emit(state.copyWith(
          requestState: RequestState.loaded,
          step: RecoverStep.setPassword,
          isStepValid: false,
          message: data.message,
        ));
      case Failure(message: final message):
        emit(state.copyWith(requestState: RequestState.error, message: message));
        if (event.context.mounted) {
          ToastManager.showToast(event.context, message: message, isError: true);
        }
    }
  }

  Future<void> _onResetPassword(
    RecoverResetPasswordEvent event,
    Emitter<RecoverPasswordState> emit,
  ) async {
    if (state.formKey.currentState?.validate() == false) return;

    emit(state.copyWith(requestState: RequestState.loading));
    final result = await resetWithOtpUseCase(
      ResetWithOtpParameter(
        email: state.emailController.text.trim(),
        code: state.codeController.text.trim(),
        password: state.passwordController.text,
      ),
    );

    switch (result) {
      case Success(data: final data):
        emit(state.copyWith(requestState: RequestState.loaded, message: data.message));
        if (event.context.mounted) {
          ToastManager.showToast(event.context, message: data.message);
          event.context.go(AuthRoutes.login);
        }
      case Failure(message: final message):
        emit(state.copyWith(requestState: RequestState.error, message: message));
        if (event.context.mounted) {
          ToastManager.showToast(event.context, message: message, isError: true);
        }
    }
  }

  void _onTogglePassword(
    RecoverTogglePasswordEvent event,
    Emitter<RecoverPasswordState> emit,
  ) =>
      emit(state.copyWith(
        isPassword: !state.isPassword,
        passwordSuffix:
            state.isPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      ));

  void _onToggleConfirm(
    RecoverToggleConfirmEvent event,
    Emitter<RecoverPasswordState> emit,
  ) =>
      emit(state.copyWith(
        isConfirmPassword: !state.isConfirmPassword,
        confirmSuffix: state.isConfirmPassword
            ? Icons.visibility_outlined
            : Icons.visibility_off_outlined,
      ));

  void _onUpdateValidation(
    RecoverUpdateValidationEvent event,
    Emitter<RecoverPasswordState> emit,
  ) {
    final valid = switch (state.step) {
      RecoverStep.enterEmail => state.emailController.text.trim().isNotEmpty,
      RecoverStep.enterCode => state.codeController.text.trim().length >= 4,
      RecoverStep.setPassword => state.passwordController.text.length >= 6 &&
          state.passwordController.text == state.confirmController.text,
    };

    if (state.isStepValid != valid) {
      emit(state.copyWith(isStepValid: valid));
    }
  }

  void _onBackToStart(
    RecoverBackToStartEvent event,
    Emitter<RecoverPasswordState> emit,
  ) {
    _timer?.cancel();
    emit(state.copyWith(
      step: RecoverStep.enterEmail,
      isStepValid: true,
      resendSeconds: 0,
    ));
  }

  void _onTick(RecoverTickEvent event, Emitter<RecoverPasswordState> emit) {
    final next = state.resendSeconds - 1;
    if (next <= 0) {
      _timer?.cancel();
      emit(state.copyWith(resendSeconds: 0));
    } else {
      emit(state.copyWith(resendSeconds: next));
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isClosed) {
        _timer?.cancel();
        return;
      }
      add(const RecoverTickEvent());
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    state.emailController.dispose();
    state.codeController.dispose();
    state.passwordController.dispose();
    state.confirmController.dispose();
    return super.close();
  }
}
