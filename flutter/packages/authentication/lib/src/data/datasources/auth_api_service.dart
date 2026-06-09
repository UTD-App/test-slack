import 'package:utd_app/network/services/base_api_service.dart';

class AuthApiService extends BaseApiService {
  static const String _login = '/auth/login';
  static const String _checkEmail = '/check-email';
  static const String _register = '/auth/register';
  static const String _forgotPassword = '/auth/forgot-password';
  static const String _resetPassword = '/auth/reset-password';
  static const String _addInfo = '/profile/update';

  String get loginPath => _login;
  String get checkEmailPath => _checkEmail;
  String get registerPath => _register;
  String get forgotPasswordPath => _forgotPassword;
  String get resetPasswordPath => _resetPassword;
  String get addInfoPath => _addInfo;
}
