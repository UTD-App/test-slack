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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _featureRegistry = FeatureRegistry();
    _userDataNotifier = UserDataNotifier();
    _initializationFuture = _initializeApp();
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

    // Aggregate translations from base + all features (const en/ar maps), then
    // OVERLAY the backend (admin/DB) translations cached by TranslationService
    // for every supported language — so a language added + translated in the
    // dashboard (fr, hi, …) actually shows in the UI, not just en/ar. Backend
    // values win over the shipped defaults.
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
    _translations = merged;

    // Load the signed-in user (the login response carries no user object, only
    // id/token) so screens that need the current user id work after a restart.
    if (CacheManager.hasSession) {
      await UserSessionService.hydrate(_userDataNotifier);
    }
  }

  @override
  void dispose() {
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
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Initializing...'),
                  ],
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
