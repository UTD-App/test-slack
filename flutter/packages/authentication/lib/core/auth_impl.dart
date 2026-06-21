import 'package:authentication/src/presentation/register/bloc/register_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/single_child_widget.dart';
import 'package:utd_app/addons/addons.dart';
import 'package:utd_app/cache/cache_manager.dart';
import 'package:utd_app/config/app_config.dart';

import '../src/data/datasources/auth_api_service.dart';
import '../src/data/datasources/auth_remote_datasource.dart';
import '../src/data/repositories/auth_repository_impl.dart';
import '../src/domain/usecases/login_usecase.dart';
import '../src/domain/usecases/check_email_usecase.dart';
import '../src/domain/usecases/register_usecase.dart';
import '../src/domain/usecases/add_info_usecase.dart';
import '../src/domain/usecases/send_otp_usecase.dart';
import '../src/domain/usecases/verify_otp_usecase.dart';
import '../src/domain/usecases/reset_with_otp_usecase.dart';
import '../src/domain/usecases/forget_password_usecase.dart';
import '../src/presentation/splash/bloc/splash_bloc.dart';
import '../src/presentation/login/bloc/login_with_phone_bloc/login_bloc.dart';
import '../src/presentation/add_information/bloc/add_information_bloc.dart';
import '../src/presentation/recover_password/bloc/recover_password_bloc.dart';
import 'auth_locator.dart';
import 'auth_routes.dart';
import 'auth_strings.dart';

class AuthFeature extends AppFeature {
  late final AuthApiService _apiService;
  late final AuthRemoteDataSourceImpl _dataSource;
  late final AuthRepositoryImpl _repository;

  late final LoginUseCase _loginUseCase;
  late final CheckEmailUseCase _checkEmailUseCase;
  late final AddInfoUseCase _addInfoUseCase;
  late final RegisterUseCase _registerUseCase;
  late final SendOtpUseCase _sendOtpUseCase;
  late final VerifyOtpUseCase _verifyOtpUseCase;
  late final ResetWithOtpUseCase _resetWithOtpUseCase;
  late final ForgetPasswordUseCase _forgetPasswordUseCase;

  late final SplashBloc _splashBloc;
  late final LoginBloc _loginBloc;
  late final AddInformationBloc _addInformationBloc;
  late final RegisterBloc _registerBloc;
  late final RecoverPasswordBloc _recoverPasswordBloc;

  @override
  String get id => 'com.utd.authentication';

  @override
  bool get isCore => true;

  @override
  String get displayName => 'Authentication';

  @override
  Future<void> initialize() async {
    _apiService = AuthApiService();
    _dataSource = AuthRemoteDataSourceImpl(apiService: _apiService);
    _repository = AuthRepositoryImpl(remoteDataSource: _dataSource);

    _loginUseCase = LoginUseCase(_repository);
    _checkEmailUseCase = CheckEmailUseCase(_repository);
    _addInfoUseCase = AddInfoUseCase(_repository);
    _registerUseCase = RegisterUseCase(_repository);
    _sendOtpUseCase = SendOtpUseCase(_repository);
    _verifyOtpUseCase = VerifyOtpUseCase(_repository);
    _resetWithOtpUseCase = ResetWithOtpUseCase(_repository);
    _forgetPasswordUseCase = ForgetPasswordUseCase(_repository);

    // Expose the auth use cases to the UTD Studio core action parsers
    // (core.login / core.register / core.forgotPassword) which run inside a
    // server-driven screen, outside the BLoC layer. Filled here because the
    // addon platform awaits initialize() before any screen/route builds.
    AuthLocator.login = _loginUseCase;
    AuthLocator.checkEmail = _checkEmailUseCase;
    AuthLocator.addInfo = _addInfoUseCase;
    AuthLocator.register = _registerUseCase;
    AuthLocator.forgetPassword = _forgetPasswordUseCase;

    _splashBloc = SplashBloc(checkAuth: () => CacheManager.hasSession);
    _loginBloc = LoginBloc(
      loginUseCase: _loginUseCase,
      checkEmailUseCase: _checkEmailUseCase,
    );
    _addInformationBloc = AddInformationBloc(addInfoUseCase: _addInfoUseCase);
    _registerBloc = RegisterBloc(_registerUseCase);
    _recoverPasswordBloc = RecoverPasswordBloc(
      sendOtpUseCase: _sendOtpUseCase,
      verifyOtpUseCase: _verifyOtpUseCase,
      resetWithOtpUseCase: _resetWithOtpUseCase,
    );
  }

  @override
  Future<void> dispose() async {
    await _splashBloc.close();
    await _loginBloc.close();
    await _addInformationBloc.close();
    await _registerBloc.close();
    await _recoverPasswordBloc.close();
  }

  @override
  List<SingleChildWidget> getProviders() => [
        BlocProvider<SplashBloc>.value(value: _splashBloc),
        BlocProvider<LoginBloc>.value(value: _loginBloc),
        BlocProvider<AddInformationBloc>.value(value: _addInformationBloc),
        BlocProvider<RegisterBloc>.value(value: _registerBloc),
        BlocProvider<RecoverPasswordBloc>.value(value: _recoverPasswordBloc),
      ];

  @override
  List<GoRoute> getRoutes() => AuthRoutes.routes();

  @override
  List<UiContribution> getUiContributions() => const [];

  @override
  void registerWidgets(WidgetRegistry registry) {}

  @override
  Map<String, Map<String, String>> getTranslations() =>
      AuthStrings.translations(appConfig.appName);
}
