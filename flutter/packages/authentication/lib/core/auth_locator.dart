import '../src/domain/usecases/add_info_usecase.dart';
import '../src/domain/usecases/check_email_usecase.dart';
import '../src/domain/usecases/forget_password_usecase.dart';
import '../src/domain/usecases/login_usecase.dart';
import '../src/domain/usecases/register_usecase.dart';

/// Tiny service locator that exposes the auth use cases to code outside the
/// BLoC layer — specifically the custom Stac action parsers
/// (`core.login`, `core.register`, ...) which run inside a server-driven
/// screen where the BLoCs' private TextEditingControllers aren't populated.
///
/// Filled once by [AuthFeature.initialize], which the addon platform awaits
/// (via FeatureRegistry.initializeAll) BEFORE the router/screens build — so the
/// use cases are ready before any tap can fire an action.
class AuthLocator {
  AuthLocator._();

  static LoginUseCase? login;
  static RegisterUseCase? register;
  static CheckEmailUseCase? checkEmail;
  static AddInfoUseCase? addInfo;
  static ForgetPasswordUseCase? forgetPassword;
}
