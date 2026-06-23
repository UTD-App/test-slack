import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:go_router/go_router.dart';
import 'package:utd_app/cache/cache_manager.dart';
import 'package:utd_app/shared/core/enums.dart';
import 'package:utd_app/shared/core/toast_manager.dart';

import '../../../../core/auth_routes.dart';
import '../../../domain/params/register_parameter.dart';
import '../../../domain/usecases/register_usecase.dart';

part 'register_event.dart';
part 'register_state.dart';

class RegisterBloc extends Bloc<BaseRegisterEvent, RegisterState> {
  final RegisterUseCase _registerUseCase;

  RegisterBloc(this._registerUseCase)
    : super(
        RegisterState(
          formKey: GlobalKey<FormState>(),
          emailController: TextEditingController(),
          passwordController: TextEditingController(),
        ),
      ) {
    on<RegisterEvent>(_registerEvent);
    on<TogglePasswordVisibilityEvent>(_toggleEvent);
    on<ValidEventRegister>(_validEventRegister);
  }

  void _validEventRegister(
    ValidEventRegister event,
    Emitter<RegisterState> emit,
  ) {
    final isValid =
        state.emailController.text.isNotEmpty &&
        state.passwordController.text.isNotEmpty;

    if (state.isFormValid != isValid) {
      emit(state.copyWith(isFormValid: isValid));
    }
  }

  void _toggleEvent(
    TogglePasswordVisibilityEvent event,
    Emitter<RegisterState> emit,
  ) {
    emit(
      state.copyWith(
        isPassword: !state.isPassword,
        suffixIcon: state.isPassword
            ? Icons.visibility_outlined
            : Icons.visibility_off_outlined,
      ),
    );
  }

  Future<void> _registerEvent(
    RegisterEvent event,
    Emitter<RegisterState> emit,
  ) async {
    if (state.formKey.currentState?.validate() == false) return;

    emit(state.copyWith(reqState: RequestState.loading));
    final result = await _registerUseCase(
      RegisterParameter(
        email: state.emailController.text.trim(),
        password: state.passwordController.text,
      ),
    );

    result.when(
      success: (data) async {
        emit(
          state.copyWith(reqState: RequestState.loaded, message: data.message),
        );

        await CacheManager.saveToken(data.data ?? '');

        if (event.context.mounted) {
          ToastManager.showToast(event.context, message: data.message);
          event.context.go(AuthRoutes.addInformation);
        }
      },
      failure: (message, _) {
        emit(
          state.copyWith(reqState: RequestState.error, message: message),
        );
        if (event.context.mounted) {
          ToastManager.showToast(
            event.context,
            message: message,
            isError: true,
          );
        }
      },
    );
  }

  @override
  Future<void> close() {
    state.emailController.dispose();
    state.passwordController.dispose();
    return super.close();
  }
}
