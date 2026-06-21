import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:utd_app/shared/core/color_manager.dart';
import 'package:utd_app/shared/widgets/gradient_background.dart';

import '../src/presentation/splash/view/splash_page.dart';
import '../src/presentation/on_boarding/on_boarding_screen.dart';
import '../src/presentation/intro/view/intro_page.dart';
import '../src/presentation/login/view/login_page.dart';
import '../src/presentation/register/view/register_page.dart';
import '../src/presentation/add_information/view/add_information_page.dart';
import '../src/presentation/recover_password/view/recover_password_page.dart';

class AuthRoutes {
  AuthRoutes._();

  static const String splash = '/splash';
  static const String onBoarding = '/on-boarding';
  static const String intro = '/intro';
  static const String login = '/login';
  static const String register = '/register';
  static const String addInformation = '/add-information';

  static const String recoverPassword = '/recover-password';

  static const String privacy = '/privacy';
  static const String layout = '/';
  static const String languageScreen = '/language-screen';
  static const String bannerScreen = '/banner-screen';
  static const String refreshScreen = '/refresh-screen';

  static List<GoRoute> routes() => [
        GoRoute(
          path: splash,
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: onBoarding,
          builder: (context, state) => const OnBoardingScreen(),
        ),
        GoRoute(
          path: intro,
          builder: (context, state) => IntroPage(
            error: state.extra as String?,
          ),
        ),
        GoRoute(
          path: login,
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: register,
          builder: (context, state) {
            final args = state.extra as Map<String, dynamic>? ?? {};
            return RegisterPage(
              initialEmail: args['email'] as String?,
            );
          },
        ),
        GoRoute(
          path: addInformation,
          builder: (context, state) => const AddInformationPage(),
        ),
        GoRoute(
          path: recoverPassword,
          builder: (context, state) => const RecoverPasswordPage(),
        ),
        GoRoute(
          path: privacy,
          builder: (context, state) => Scaffold(
            backgroundColor: ColorManager.authBgGradient.last,
            appBar: AppBar(
              backgroundColor: ColorManager.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: ColorManager.white),
            ),
            extendBodyBehindAppBar: true,
            body: const GradientBackground(
              colors: ColorManager.authBgGradient,
              child: Center(
                child: Text(
                  'Privacy Policy',
                  style: TextStyle(color: ColorManager.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ),
      ];
}
