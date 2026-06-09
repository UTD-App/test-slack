/// App Flow & Screen Contract — the data-driven navigation contract between UTD
/// Studio (the no-code builder) and this Flutter runtime.
///
/// The whole point: a screen's *display name* is cosmetic (the customer renames
/// it freely). What the runtime acts on is the **contract** — a screen's
/// semantic [role] and its entry [requiresAuth]/[showOnce] policies — plus a
/// single global [AppFlow] map that says which route fills each well-known
/// *slot* (where to go when unauthenticated, where home is, what shows once on
/// first run, …). No magic names, no hardcoded "login" string in the logic.
///
/// ## How it's consumed (the entire Flutter surface — fixed, ~one place each):
///  1. Boot: [AppFlow.resolveStart] decides splash → firstRun / unauthenticated
///     / home.
///  2. Route guard: a GoRouter `redirect` reads [contractFor] —
///     `requiresAuth && !session` → [unauthenticated]; an already-seen
///     `showOnce` screen → away.
///  3. 401 / expired: the API client clears the session → the guard sends the
///     next navigation to [unauthenticated] (same destination as logged-out).
///  4. Actions resolve named outcomes from the flow ([onAuthSuccess],
///     [onLogout]) instead of hardcoding routes.
///
/// ## Hybrid ownership
/// The base declares the *slots* and their behaviour (this file). The customer,
/// in Studio, picks *which screen* fills each slot — delivered later via the
/// manifest and applied with [AppFlow.override]. Until then [AppFlow.instance]
/// is [AppFlow.fallback], which mirrors the base's own core screens.
library;

/// Curated, open vocabulary of screen roles. `custom:<name>` is allowed for
/// anything outside this set — the runtime only special-cases what it knows.
class ScreenRoles {
  ScreenRoles._();

  static const String login = 'auth.login';
  static const String register = 'auth.register';
  static const String forgot = 'auth.forgot';
  static const String profile = 'auth.profile';
  static const String intro = 'onboarding.intro';
  static const String home = 'app.home';
  static const String settings = 'app.settings';
  static const String splash = 'app.splash';
}

/// Per-screen self-description. Defaults are inert: a plain content screen has
/// no role and no special entry policy.
class ScreenContract {
  /// Semantic role from [ScreenRoles] (or `custom:<name>`), or null.
  final String? role;

  /// If true, entering this screen without a session redirects to
  /// [AppFlow.unauthenticated].
  final bool requiresAuth;

  /// If true, this screen is shown at most once in the app's lifetime; once
  /// seen, the guard routes away from it.
  final bool showOnce;

  const ScreenContract({
    this.role,
    this.requiresAuth = false,
    this.showOnce = false,
  });
}

/// Global named-slot → route map. Every slot value is just a route path, so any
/// screen can fill any slot.
class AppFlow {
  /// Shown on every launch while the start route is resolved.
  final String splash;

  /// The first-run / landing route (an [ScreenRoles.intro] screen). Shown once.
  final String firstRun;

  /// Where to send an unauthenticated user (also the destination on expiry).
  final String unauthenticated;

  /// The authenticated landing route.
  final String home;

  /// Where to go after a successful login (defaults to [home]).
  final String onAuthSuccess;

  /// Where to go after logout (defaults to [unauthenticated]).
  final String onLogout;

  /// Per-route contracts, keyed by the concrete route path (e.g. `/login`,
  /// `/s/core_settings`).
  final Map<String, ScreenContract> contracts;

  const AppFlow({
    required this.splash,
    required this.firstRun,
    required this.unauthenticated,
    required this.home,
    String? onAuthSuccess,
    String? onLogout,
    this.contracts = const {},
  })  : onAuthSuccess = onAuthSuccess ?? home,
        onLogout = onLogout ?? unauthenticated;

  /// The contract for a route path (inert default if none declared).
  ScreenContract contractFor(String location) =>
      contracts[location] ?? const ScreenContract();

  /// The boot decision. [seen] reports whether a route's "shown once" flag is
  /// already set (see CacheManager.seen).
  ///  • session            → [home]
  ///  • first run ever      → [firstRun]
  ///  • returning, no auth  → [unauthenticated]
  String resolveStart({
    required bool hasSession,
    required bool Function(String route) seen,
  }) {
    if (hasSession) return home;
    if (!seen(firstRun)) return firstRun;
    return unauthenticated;
  }

  // ── Active configuration ───────────────────────────────────────────────────

  static AppFlow _instance = fallback;

  /// The flow in effect. Defaults to [fallback]; replace at startup once the
  /// customer's flow is delivered from the manifest.
  static AppFlow get instance => _instance;

  /// Apply a customer-configured flow (e.g. parsed from the manifest).
  static void override(AppFlow flow) => _instance = flow;

  /// The base project's own core screens — used until a customer flow is set.
  static const AppFlow fallback = AppFlow(
    splash: '/splash',
    firstRun: '/intro',
    unauthenticated: '/login',
    home: '/',
    contracts: {
      '/intro': ScreenContract(role: ScreenRoles.intro, showOnce: true),
      '/login': ScreenContract(role: ScreenRoles.login),
      '/register': ScreenContract(role: ScreenRoles.register),
      '/recover-password': ScreenContract(role: ScreenRoles.forgot),
      '/': ScreenContract(role: ScreenRoles.home, requiresAuth: true),
      '/profile': ScreenContract(role: ScreenRoles.profile, requiresAuth: true),
    },
  );
}
