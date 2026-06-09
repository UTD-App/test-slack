import 'package:authentication/core/auth_routes.dart';
import 'package:go_router/go_router.dart';
import '../addons/feature_registry.dart';
import '../cache/cache_manager.dart';
import 'app_flow.dart';
import 'app_layout_service.dart';
import '../screens/app_shell.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../shared/stac/stac_dynamic_screen.dart';

GoRouter createRouter(FeatureRegistry registry) {
  return GoRouter(
    initialLocation: AuthRoutes.splash,
    // Screen-contract guard: enforces each route's declared policy from the
    // active [AppFlow] — no per-screen wiring, no magic names.
    redirect: (context, state) {
      final flow = AppFlow.instance;
      final contract = flow.contractFor(state.matchedLocation);
      final hasSession = CacheManager.hasSession;

      // Protected screen reached without a session → unauthenticated slot.
      if (contract.requiresAuth && !hasSession) return flow.unauthenticated;

      // "Show once": if already seen, route away; otherwise let it through and
      // mark it seen now (it's about to be shown) so it never appears again.
      if (contract.showOnce) {
        if (CacheManager.seen(state.matchedLocation)) {
          return hasSession ? flow.home : flow.unauthenticated;
        }
        CacheManager.markSeen(state.matchedLocation);
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          // Server-driven home shell when the app_layout document defines a
          // bottom nav; otherwise the native feature-registry HomeScreen.
          final nav = AppLayoutService.instance.navConfig.value;
          if (nav != null && nav.enabled && nav.tabs.isNotEmpty) {
            return AppShell(config: nav, registry: registry);
          }
          return const HomeScreen();
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const StacDynamicScreen(
          screenName: 'core_profile',
          fallback: ProfileScreen(),
        ),
      ),
      // Generic server-driven screen: /s/<screenName> renders JSON pushed
      // from UTD Studio.
      GoRoute(
        path: '/s/:name',
        builder: (context, state) =>
            StacDynamicScreen(screenName: state.pathParameters['name']!),
      ),
      ...registry.aggregateRoutes(),
    ],
  );
}
