import 'package:audio_room/audio_room.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:utd_app/cache/cache_manager.dart';
import 'package:utd_app/config/app_theme.dart';
import 'package:utd_app/config/theme_notifier.dart';
import 'package:utd_app/shared/core/color_manager.dart';
import 'package:utd_app/shared/notifiers/user_data_notifier.dart';
import 'package:utd_app/shared/services/user_session_service.dart';
import 'package:utd_app/shared/services/translation_service.dart';
import 'package:utd_app/services/launch_gate_service.dart';
import 'package:utd_app/services/package_gate_service.dart';
import 'package:utd_app/screens/launch_gate_screen.dart';
import 'addons/addons.dart';
import 'config/router.dart';
import 'localization/localization.dart';

/// Root widget for the Add-on Platform application.
///
/// **Core app responsibility**:
/// - Feature initialization and lifecycle
/// - FeatureRegistry management
/// - Router creation with aggregated routes
/// - Theme and global configuration
/// - Localization management
///
/// **Feature responsibility**:
/// - Route definitions
/// - UI contributions
/// - Widget registrations
/// - Feature-specific logic
/// - Feature-specific translations
///
/// Features are prepared before the app renders to ensure routes,
/// UI contributions, and translations are available immediately.
class AddonPlatformApp extends StatefulWidget {
  /// All features (both enabled and disabled).
  final List<AppFeature> allFeatures;

  /// IDs of features the user has disabled.
  final Set<String> disabledFeatureIds;

  /// Selected UI contribution key per feature (featureId → contributionKey).
  final Map<String, String> selectedContributions;

  /// Locale notifier for managing the current locale.
  final LocaleNotifier localeNotifier;

  /// Theme notifier for managing light/dark mode.
  final ThemeNotifier themeNotifier;

  const AddonPlatformApp({
    super.key,
    required this.allFeatures,
    this.disabledFeatureIds = const {},
    this.selectedContributions = const {},
    required this.localeNotifier,
    required this.themeNotifier,
  });

  @override
  State<AddonPlatformApp> createState() => _AddonPlatformAppState();
}

class _AddonPlatformAppState extends State<AddonPlatformApp>
    with WidgetsBindingObserver {
  late final FeatureRegistry _featureRegistry;
  late final UserDataNotifier _userDataNotifier;
  late final Future<void> _initializationFuture;
  late Map<String, Map<String, String>> _translations;
  LaunchGateResult _gate = LaunchGateResult.none;
  bool _softUpdateShown = false;
  DateTime? _lastGateCheck;
  GoRouter? _router;

  /// Locale codes whose backend translations we've already kicked off a sync for
  /// this session, so a rapid back-and-forth language switch doesn't fan out
  /// duplicate fetches.
  final Set<String> _syncingLocales = {};

  /// True once _initializeApp has built the first translation table — guards the
  /// locale-switch rebuild against running before init (registry/_translations).
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _featureRegistry = FeatureRegistry();
    _userDataNotifier = UserDataNotifier();
    // Backend is the source of truth for UI strings: when the user switches to a
    // language we haven't fetched yet, lazily pull it and rebuild the overlay so
    // the menu/labels flip without a relaunch (the startup sync only covers the
    // launch locale). Version-gated in TranslationService → cheap/no-op if cached.
    widget.localeNotifier.addListener(_onLocaleChanged);
    _initializationFuture = _initializeApp();
  }

  void _onLocaleChanged() {
    if (!_ready) return; // init builds the first table; nothing to rebuild yet
    _syncLocale(widget.localeNotifier.locale.languageCode);
  }

  /// Pull a locale's latest backend translations (version-gated → a tiny /version
  /// check, downloads only when it changed) and rebuild the overlay when they
  /// land. Called on startup, language switch and app resume so a translation
  /// edited in the dashboard shows the SAME relaunch/resume — the overlay is built
  /// once from the Hive cache, which can be a version stale, so without this the
  /// fresh data only surfaced on the *next* launch (the "kill twice" symptom).
  void _syncLocale(String code) {
    if (_syncingLocales.contains(code)) return;
    _syncingLocales.add(code);
    TranslationService.instance.sync(code).whenComplete(() {
      _syncingLocales.remove(code);
      if (!mounted) return;
      setState(() => _translations = _aggregateTranslations());
    });
  }

  /// Re-check the launch gate when the app returns to the foreground, so an
  /// admin flipping maintenance / force-update on takes effect without a cold
  /// restart. Fails open via [LaunchGateService.check].
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // Throttle: don't hit the backend on every quick foreground switch.
    final last = _lastGateCheck;
    if (last != null &&
        DateTime.now().difference(last) < const Duration(seconds: 60)) {
      return;
    }
    _lastGateCheck = DateTime.now();
    // Pick up dashboard translation edits on foreground (version-gated → cheap).
    if (_ready) _syncLocale(widget.localeNotifier.locale.languageCode);
    LaunchGateService.check().then((gate) {
      if (!mounted) return;
      if (gate.blocks != _gate.blocks ||
          gate.forceUpdate != _gate.forceUpdate ||
          gate.maintenance != _gate.maintenance) {
        setState(() => _gate = gate);
      }
    });
  }

  Future<void> _initializeApp() async {
    // Apply last-known branding/colors from cache instantly (offline-safe),
    // then refresh from the backend below.
    LaunchGateService.loadCached();

    // Launch gate + package gate, in parallel (both are launch-time network
    // reads, both fail open). The package gate learns which backend packages are
    // enabled so a package disabled from the dashboard is treated as not
    // installed here too — its feature is skipped and never calls dead routes.
    final results = await Future.wait([
      LaunchGateService.check(),
      PackageGateService.sync(),
    ]);
    _gate = results[0] as LaunchGateResult;
    final enabledPackages = results[1] as Set<String>?;
    _lastGateCheck = DateTime.now();

    _featureRegistry.addFeatures(widget.allFeatures);

    // Local Studio toggles + backend-disabled packages. A feature is auto-
    // disabled when it declares a [packageSlug] the backend reports as NOT
    // enabled. `null` enabledPackages = unknown (offline, never fetched) → fail
    // open: disable nothing, matching the backend's "absent ⇒ enabled".
    final disabled = {...widget.disabledFeatureIds};
    if (enabledPackages != null) {
      for (final feature in widget.allFeatures) {
        final slug = feature.packageSlug;
        if (slug != null && !enabledPackages.contains(slug)) {
          disabled.add(feature.id);
        }
      }
    }
    _featureRegistry.setDisabledFeatures(disabled);
    _featureRegistry.setSelectedContributions(widget.selectedContributions);

    await _featureRegistry.initializeAll();

    _translations = _aggregateTranslations();

    // Load the signed-in user (the login response carries no user object, only
    // id/token) so screens that need the current user id work after a restart.
    if (CacheManager.hasSession) {
      await UserSessionService.hydrate(_userDataNotifier);
    }

    _ready = true; // locale-switch rebuilds are safe from here on

    // The overlay above was built from the (possibly stale) Hive cache. Refresh
    // the launch locale from the backend and rebuild when it lands, so a
    // dashboard edit appears after ONE relaunch (or the next resume) — not two.
    _syncLocale(widget.localeNotifier.locale.languageCode);
  }

  /// Build the active translation table: base + all feature const en/ar maps,
  /// then OVERLAY the backend (admin/DB) translations cached by TranslationService
  /// for every supported language — so a language added + translated in the
  /// dashboard (fr, hi, …) shows in the UI, not just en/ar. Backend values win
  /// over the shipped defaults. Re-run on locale switch ({@see _onLocaleChanged}).
  Map<String, Map<String, String>> _aggregateTranslations() {
    final merged = <String, Map<String, String>>{};
    _featureRegistry
        .aggregateTranslations(baseTranslations)
        .forEach((code, map) => merged[code] = {...map});
    for (final locale in widget.localeNotifier.supportedLocales) {
      final code = locale.languageCode;
      final backend = TranslationService.instance.getAll(code);
      if (backend.isNotEmpty) {
        merged[code] = {...?merged[code], ...backend};
      }
    }
    return merged;
  }

  @override
  void dispose() {
    widget.localeNotifier.removeListener(_onLocaleChanged);
    WidgetsBinding.instance.removeObserver(this);
    _featureRegistry.disposeAll();
    _featureRegistry.dispose();
    super.dispose();
  }

  /// Dark-purple Material3 theme (live-app aesthetic).
  ///
  /// The colorScheme pins the roles existing screens read directly
  /// (surface/onSurface/primary/primaryContainer/onSurfaceVariant/outline)
  /// so cards and text stay readable on the dark background — settings_screen
  /// is the canary for this mapping.
  static ThemeData _lumiaTheme() {
    // Colors come from the admin palette (each defaulting to the built-in lumia
    // value), so the dashboard's "Colors" tab restyles the app at launch.
    final p = AppThemeProvider.current;
    final scheme = ColorScheme.fromSeed(
      seedColor: p.primary,
      brightness: Brightness.dark,
    ).copyWith(
      surface: p.bgDark,
      onSurface: p.textPrimary,
      primary: p.primary,
      onPrimary: ColorManager.white,
      primaryContainer: p.cardBorder,
      onPrimaryContainer: ColorManager.white,
      secondary: p.accent,
      onSurfaceVariant: p.textSecondary,
      outline: p.textSecondary,
      error: ColorManager.error,
    );

    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: p.bgDark,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: p.bgDark,
        foregroundColor: p.textPrimary,
      ),
      cardTheme: CardThemeData(
        color: p.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomAppBarTheme: const BottomAppBarThemeData(
        color: ColorManager.lumiaBgMedium,
      ),
      useMaterial3: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Branded boot screen (matches the splash identity) instead of a bare
          // white scaffold with a black spinner — the latter looked like a dev
          // placeholder on every relaunch.
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: _lumiaTheme(),
            home: Scaffold(
              body: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: ColorManager.authBgGradient,
                  ),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: ColorManager.white),
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text('Initialization failed: ${snapshot.error}'),
              ),
            ),
          );
        }

        // Launch gate wins over everything: force-update / maintenance block the
        // whole app shell before the router is ever built.
        if (_gate.blocks) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: _lumiaTheme(),
            home: LaunchGateScreen(
              result: _gate,
              localeCode: widget.localeNotifier.locale.languageCode,
            ),
          );
        }

        // App is ready - create router once to preserve navigation state across hot reloads
        _router ??= createRouter(_featureRegistry);
        final router = _router!;

        // Provide registries and locale notifier to all screens
        return MultiProvider(
          providers: [
            ChangeNotifierProvider<FeatureRegistry>.value(
              value: _featureRegistry,
            ),
            ChangeNotifierProvider<LocaleNotifier>.value(
              value: widget.localeNotifier,
            ),
            ChangeNotifierProvider<ThemeNotifier>.value(
              value: widget.themeNotifier,
            ),
            ChangeNotifierProvider<UserDataNotifier>.value(
              value: _userDataNotifier,
            ),
            ChangeNotifierProvider<RoleRegistry>.value(
              value: _featureRegistry.roleRegistry,
            ),
            ChangeNotifierProvider<SettingsRegistry>.value(
              value: _featureRegistry.settingsRegistry,
            ),
            ..._featureRegistry.features.expand(
              (feature) => feature.getProviders(),
            ),
          ],
          child: Builder(
            builder: (context) {
              final localeNotifier = context.watch<LocaleNotifier>();
              final themeNotifier = context.watch<ThemeNotifier>();

              return ScreenUtilInit(
                designSize: const Size(375, 812),
                minTextAdapt: true,
                splitScreenMode: true,
                builder: (context, child) {
                  return MaterialApp.router(
                    // App name comes from admin branding (default 'Tempo').
                    title: AppInfoProvider.current.name,
                    debugShowCheckedModeBanner: false,
                    locale: localeNotifier.locale,
                    supportedLocales: localeNotifier.supportedLocales,
                    builder: (context, child) {
                      if (!_gate.blocks &&
                          _gate.updateAvailable &&
                          !_softUpdateShown) {
                        _softUpdateShown = true;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          showSoftUpdateDialog(
                            context,
                            storeUrl: _gate.storeUrl,
                            localeCode: localeNotifier.locale.languageCode,
                          );
                        });
                      }
                      return AudioRoomAppOverlay(
                        router: router,
                        child: child ?? const SizedBox.shrink(),
                      );
                    },
                    localizationsDelegates: [
                      AppLocalizationsDelegate(_translations),
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    theme: _lumiaTheme(),
                    darkTheme: _lumiaTheme(),
                    themeMode: themeNotifier.themeMode,
                    routerConfig: router,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
