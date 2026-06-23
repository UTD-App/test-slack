import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:go_router/go_router.dart';
import 'package:utd_app/cache/cache_manager.dart';
import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/shared/core/enums.dart';
import 'package:utd_app/shared/core/toast_manager.dart';
import 'package:utd_app/shared/notifiers/user_data_notifier.dart';
import 'package:utd_app/shared/services/user_session_service.dart';

import '../../../../domain/params/auth_parameter.dart';
import '../../../../domain/usecases/login_usecase.dart';
import '../../../../domain/usecases/check_email_usecase.dart';
import '../../../../../core/auth_routes.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final LoginUseCase loginUseCase;
  final CheckEmailUseCase checkEmailUseCase;

  LoginBloc({required this.loginUseCase, required this.checkEmailUseCase})
    : super(
        LoginState(
          formKey: GlobalKey<FormState>(),
          passwordController: TextEditingController(),
          emailController: TextEditingController(),
        ),
      ) {
    on<TogglePasswordEvent>(_toggleEvent);
    on<LoginWithEmailEvent>(_loginEvent);
    on<UpdateFormValidationEvent>(_updateFormValidation);
    on<CheckEmailEvent>(_checkEmail);
    on<ResetLoginStateEvent>((event, emit) {
      emit(state.copyWith(isFoundAccount: null, showRegisterDialog: false));
    });
  }

  Future<void> _checkEmail(CheckEmailEvent event, Emitter<LoginState> emit) async {
    if (state.formKey.currentState?.validate() == false) return;

    emit(state.copyWith(requestStateCheckEmail: RequestState.loading));
    final result = await checkEmailUseCase(state.emailController.text.trim());

    result.when(
      success: (data) {
        emit(
          state.copyWith(
            message: data.message,
            isFoundAccount: data.data,
            requestStateCheckEmail: RequestState.loaded,
            showRegisterDialog: data.data == false,
          ),
        );
      },
      failure: (message, _) {
        emit(
          state.copyWith(
            message: message,
            requestStateCheckEmail: RequestState.error,
          ),
        );
      },
    );
  }

  void _toggleEvent(TogglePasswordEvent event, Emitter<LoginState> emit) =>
      emit(
        state.copyWith(
          isPassword: !state.isPassword,
          suffixIcon: state.isPassword
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
        ),
      );

  Future<void> _loginEvent(LoginWithEmailEvent event, Emitter<LoginState> emit) async {
    if (state.formKey.currentState?.validate() == false) return;

    emit(state.copyWith(requestState: RequestState.loading));
    final result = await loginUseCase(
      AuthParameter(
        email: state.emailController.text.trim(),
        password: state.passwordController.text,
      ),
    );

    switch (result) {
      case Success(data: final data):
        final entity = data.data;
        if (entity != null) {
          await CacheManager.saveToken(entity.authToken);
          // The login response carries no user object (only id/is_first/token),
          // so load the current user from /my-data into the notifier + cache.
          if (event.context.mounted) {
            await UserSessionService.hydrate(
              event.context.read<UserDataNotifier>(),
            );
          }
        }

        emit(
          state.copyWith(
            message: data.message,
            requestState: RequestState.loaded,
          ),
        );

        if (event.context.mounted) {
          ToastManager.showToast(event.context, message: data.message);
          event.context.go(AuthRoutes.layout);
        }
      case Failure(message: final message):
        emit(
          state.copyWith(message: message, requestState: RequestState.error),
        );
        if (event.context.mounted) {
          ToastManager.showToast(
            event.context,
            message: message,
            isError: true,
          );
        }
    }
  }

  void _updateFormValidation(
    UpdateFormValidationEvent event,
    Emitter<LoginState> emit,
  ) {
    bool isValid =
        state.emailController.text.isNotEmpty &&
        state.passwordController.text.isNotEmpty;

    if (state.isFormValid != isValid) {
      emit(state.copyWith(isFormValid: isValid));
    }
  }

  @override
  Future<void> close() {
    state.passwordController.dispose();
    state.emailController.dispose();
    return super.close();
  }
}
