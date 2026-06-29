import 'package:authentication/src/presentation/login/bloc/login_with_phone_bloc/login_bloc.dart';
import 'package:authentication/src/presentation/recover_password/bloc/recover_password_bloc.dart';
import 'package:authentication/src/presentation/register/bloc/register_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utd_app/shared/core/enums.dart';

void main() {
  // States hold TextEditingControllers / GlobalKeys → need the binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LoginState', () {
    LoginState fresh() => LoginState(
          formKey: GlobalKey<FormState>(),
          passwordController: TextEditingController(),
          emailController: TextEditingController(),
        );

    test('default values', () {
      final s = fresh();
      expect(s.requestState, RequestState.idle);
      expect(s.requestStateCheckEmail, RequestState.idle);
      expect(s.isPassword, true);
      expect(s.suffixIcon, Icons.visibility_outlined);
      expect(s.message, '');
      expect(s.isFormValid, isNull);
      expect(s.isFoundAccount, isNull);
      expect(s.showRegisterDialog, false);
    });

    test('copyWith overrides only the provided fields', () {
      final s = fresh();
      final next = s.copyWith(
        requestState: RequestState.loading,
        isPassword: false,
        message: 'err',
        showRegisterDialog: true,
      );
      expect(next.requestState, RequestState.loading);
      expect(next.isPassword, false);
      expect(next.message, 'err');
      expect(next.showRegisterDialog, true);
      // Untouched fields preserved.
      expect(next.requestStateCheckEmail, RequestState.idle);
      expect(next.suffixIcon, Icons.visibility_outlined);
    });

    test('copyWith keeps the same controllers/formKey (identity preserved)', () {
      final s = fresh();
      final next = s.copyWith(message: 'x');
      expect(identical(next.formKey, s.formKey), isTrue);
      expect(identical(next.emailController, s.emailController), isTrue);
      expect(identical(next.passwordController, s.passwordController), isTrue);
    });

    test('Equatable: a no-op copyWith equals the original', () {
      final s = fresh();
      expect(s.copyWith(), equals(s));
    });

    test('Equatable: changing a prop breaks equality', () {
      final s = fresh();
      expect(s.copyWith(message: 'changed'), isNot(equals(s)));
    });
  });

  group('RegisterState', () {
    RegisterState fresh() => RegisterState(
          formKey: GlobalKey<FormState>(),
          emailController: TextEditingController(),
          passwordController: TextEditingController(),
        );

    test('default values', () {
      final s = fresh();
      expect(s.isPassword, true);
      expect(s.suffixIcon, Icons.visibility_outlined);
      expect(s.reqState, RequestState.idle);
      expect(s.message, '');
      expect(s.isFormValid, false);
    });

    test('copyWith overrides provided fields, preserves the rest', () {
      final s = fresh();
      final next = s.copyWith(reqState: RequestState.loaded, isFormValid: true);
      expect(next.reqState, RequestState.loaded);
      expect(next.isFormValid, true);
      expect(next.isPassword, true); // untouched
      expect(next.message, ''); // untouched
    });

    test('copyWith preserves controllers/formKey identity', () {
      final s = fresh();
      final next = s.copyWith(message: 'm');
      expect(identical(next.formKey, s.formKey), isTrue);
      expect(identical(next.emailController, s.emailController), isTrue);
    });

    test('Equatable no-op copyWith equals original', () {
      final s = fresh();
      expect(s.copyWith(), equals(s));
    });
  });

  group('RecoverPasswordState', () {
    RecoverPasswordState fresh() => RecoverPasswordState(
          formKey: GlobalKey<FormState>(),
          emailController: TextEditingController(),
          codeController: TextEditingController(),
          passwordController: TextEditingController(),
          confirmController: TextEditingController(),
        );

    test('default values', () {
      final s = fresh();
      expect(s.step, RecoverStep.enterEmail);
      expect(s.requestState, RequestState.idle);
      expect(s.isPassword, true);
      expect(s.isConfirmPassword, true);
      expect(s.passwordSuffix, Icons.visibility_outlined);
      expect(s.confirmSuffix, Icons.visibility_outlined);
      expect(s.isStepValid, isNull);
      expect(s.resendSeconds, 0);
      expect(s.message, '');
    });

    test('RecoverStep enum has the three flow steps in order', () {
      expect(RecoverStep.values,
          [RecoverStep.enterEmail, RecoverStep.enterCode, RecoverStep.setPassword]);
    });

    test('copyWith advances the step and resend countdown', () {
      final s = fresh();
      final next = s.copyWith(step: RecoverStep.enterCode, resendSeconds: 30);
      expect(next.step, RecoverStep.enterCode);
      expect(next.resendSeconds, 30);
      // Other fields preserved.
      expect(next.requestState, RequestState.idle);
      expect(next.isPassword, true);
    });

    test('copyWith toggles password visibility independently', () {
      final s = fresh();
      final next = s.copyWith(isPassword: false);
      expect(next.isPassword, false);
      expect(next.isConfirmPassword, true); // independent
    });

    test('copyWith preserves all four controllers + formKey identity', () {
      final s = fresh();
      final next = s.copyWith(message: 'm');
      expect(identical(next.formKey, s.formKey), isTrue);
      expect(identical(next.emailController, s.emailController), isTrue);
      expect(identical(next.codeController, s.codeController), isTrue);
      expect(identical(next.passwordController, s.passwordController), isTrue);
      expect(identical(next.confirmController, s.confirmController), isTrue);
    });

    test('Equatable no-op copyWith equals original; change breaks it', () {
      final s = fresh();
      expect(s.copyWith(), equals(s));
      expect(s.copyWith(resendSeconds: 5), isNot(equals(s)));
    });
  });
}
