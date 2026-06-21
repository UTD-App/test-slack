import 'package:authentication/core/auth_routes.dart';
import 'package:go_router/go_router.dart';
import '../addons/feature_registry.dart';
import '../features/search/search_page.dart';
import '../screens/contact_us_screen.dart';
import '../screens/content_page.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/visited_profile_fallback.dart';

GoRouter createRouter(FeatureRegistry registry) {
  return GoRouter(
    initialLocation: AuthRoutes.splash,
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/search', builder: (context, state) => const SearchPage()),
      // Basic read-only profile for another user, shown when the Profile package
      // isn't installed (ProfileNavigator routes here as the fallback).
      GoRoute(
        path: '/user/:id',
        builder: (context, state) => VisitedProfileFallback(
          userId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
          path: '/profile',
          builder: (context, state) => ProfileScreen(coverArgs: state.extra)),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      GoRoute(path: '/contact-us', builder: (context, state) => const ContactUsScreen()),
      GoRoute(
        path: '/page/:key',
        builder: (context, state) =>
            ContentPage(pageKey: state.pathParameters['key'] ?? ''),
      ),
      ...registry.aggregateRoutes(),
    ],
  );
}
