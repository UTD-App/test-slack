import 'package:go_router/go_router.dart';
import 'package:utd_app/screens/content_page.dart';
import 'package:utd_studio_sdk/utd_studio_sdk.dart';

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
        // intro / login / register render the UTD Studio server-driven screen
        // (screenName matches the core manifest default_screens), falling back to
        // the native page when nothing is published yet (or offline on first run)
        // — so auth never breaks before the screens are Synced+Published.
        GoRoute(
          path: intro,
          builder: (context, state) => StacDynamicScreen(
            screenName: 'intro',
            fallback: IntroPage(error: state.extra as String?),
          ),
        ),
        GoRoute(
          path: login,
          builder: (context, state) => const StacDynamicScreen(
            screenName: 'login',
            fallback: LoginPage(),
          ),
        ),
        GoRoute(
          path: register,
          builder: (context, state) {
            final args = state.extra as Map<String, dynamic>? ?? {};
            return StacDynamicScreen(
              screenName: 'register',
              fallback: RegisterPage(initialEmail: args['email'] as String?),
            );
          },
        ),
        GoRoute(
          path: addInformation,
          // add_information renders the server-driven screen (native fallback).
          builder: (context, state) => const StacDynamicScreen(
            screenName: 'add_information',
            fallback: AddInformationPage(),
          ),
        ),
        GoRoute(
          path: recoverPassword,
          builder: (context, state) => const RecoverPasswordPage(),
        ),
        // Render the real CMS page (admin-editable privacy policy) instead of a
        // placeholder. The intro footer + the register Terms link both push this
        // route, so a single point fixes the dead "Privacy Policy" link. The key
        // matches the dashboard CMS page slug (also used by the Settings screen).
        GoRoute(
          path: privacy,
          builder: (context, state) => const ContentPage(pageKey: 'privacy-policy'),
        ),
      ];
}
