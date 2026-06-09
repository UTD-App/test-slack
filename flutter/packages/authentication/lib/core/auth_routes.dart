import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:utd_app/shared/stac/stac_dynamic_screen.dart';

import '../src/presentation/splash/view/splash_page.dart';
import '../src/presentation/on_boarding/on_boarding_screen.dart';
import '../src/presentation/intro/view/intro_page.dart';
import '../src/presentation/login/view/login_page.dart';
import '../src/presentation/register/view/register_page.dart';
import '../src/presentation/add_information/view/add_information_page.dart';

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
          builder: (context, state) => StacDynamicScreen(
            screenName: 'core_intro',
            fallback: IntroPage(error: state.extra as String?),
          ),
        ),
        GoRoute(
          path: login,
          // Server-driven: renders the `core_login` screen designed in UTD
          // Studio, falling back to the built-in LoginPage if none is published.
          // (Screen names use the Studio slug convention — underscores, no dots.)
          builder: (context, state) => const StacDynamicScreen(
            screenName: 'core_login',
            fallback: LoginPage(),
          ),
        ),
        GoRoute(
          path: register,
          builder: (context, state) {
            final args = state.extra as Map<String, dynamic>? ?? {};
            return StacDynamicScreen(
              screenName: 'core_register',
              fallback: RegisterPage(initialEmail: args['email'] as String?),
            );
          },
        ),
        GoRoute(
          path: addInformation,
          builder: (context, state) => const AddInformationPage(),
        ),
        GoRoute(
          path: recoverPassword,
          builder: (context, state) => const StacDynamicScreen(
            screenName: 'core_forgot_password',
            fallback: Scaffold(
              body: Center(child: Text('Recover Password')),
            ),
          ),
        ),
        GoRoute(
          path: privacy,
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Privacy Policy')),
          ),
        ),
      ];
}
