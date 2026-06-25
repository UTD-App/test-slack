import 'package:authentication/core/auth_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:utd_studio_sdk/utd_studio_sdk.dart';
import '../addons/feature_registry.dart';
import '../config/app_layout_service.dart';
import '../features/search/search_page.dart';
import '../screens/app_shell.dart';
import '../screens/contact_us_screen.dart';
import '../screens/content_page.dart';
import '../screens/edit_profile_form.dart';
import '../screens/home_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/visited_profile_fallback.dart';

GoRouter createRouter(FeatureRegistry registry) {
  return GoRouter(
    initialLocation: AuthRoutes.splash,
    routes: [
      // Home: when UTD Studio delivered an app_layout with bottom-nav tabs, render
      // the server-driven shell (AppShell); otherwise the native HomeScreen.
      GoRoute(
        path: '/',
        builder: (context, state) {
          final nav = AppLayoutService.instance.navConfig.value;
          if (nav != null && nav.tabs.isNotEmpty) {
            return AppShell(config: nav, registry: registry);
          }
          return const HomeScreen();
        },
      ),
      GoRoute(path: '/search', builder: (context, state) => const SearchPage()),
      // UTD Studio screens are addressed by `/s/<name>` (e.g. moment.open pushes
      // `/s/moment`, core dialogs/details navigate the same way). Render the
      // published Stac screen by name; StacDynamicScreen shows its own loader /
      // fallback when the screen isn't published yet — so a server-driven push
      // never dead-ends on a GoRouter "no routes for location" error.
      GoRoute(
        path: '/s/:name',
        // A pushed Studio screen renders its own Stac scaffold which — unlike the
        // AppShell tabs — has NO top SafeArea, so its header draws under the
        // status-bar clock / camera notch. Wrap in a SafeArea (mirroring
        // AppShell's tab treatment) over a scaffold background so the strip
        // behind the status bar stays filled.
        builder: (context, state) => Scaffold(
          body: SafeArea(
            bottom: false,
            child:
                StacDynamicScreen(screenName: state.pathParameters['name'] ?? ''),
          ),
        ),
      ),
      // Basic read-only profile for another user, shown when the Profile package
      // isn't installed (ProfileNavigator routes here as the fallback).
      GoRoute(
        path: '/user/:id',
        builder: (context, state) => VisitedProfileFallback(
          userId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      // Edit profile — server-driven (UTD Studio `edit_profile` screen), with the
      // native [EditProfileForm] as the fallback until that screen is published.
      // The form is too rich for Stac primitives (image pick+upload, multi-cover,
      // save-with-state), so the Studio screen just hosts the `core.editProfileForm`
      // node — same pattern as the self-profile landing. Both the Me-landing edit
      // pencils (core.editProfile action) and the full-profile pencil push here.
      GoRoute(
          path: '/profile',
          builder: (context, state) => const StacDynamicScreen(
                screenName: 'edit_profile',
                fallback: EditProfileForm(),
              )),
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
