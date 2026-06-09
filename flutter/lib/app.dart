import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:utd_app/cache/cache_manager.dart';
import 'package:utd_app/config/app_config.dart';
import 'package:utd_app/config/theme_notifier.dart';
import 'package:utd_app/shared/core/color_manager.dart';
import 'package:utd_app/shared/notifiers/user_data_notifier.dart';
import 'package:utd_app/shared/services/user_session_service.dart';
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

class _AddonPlatformAppState extends State<AddonPlatformApp> {
  late final FeatureRegistry _featureRegistry;
  late final UserDataNotifier _userDataNotifier;
  late final Future<void> _initializationFuture;
  late Map<String, Map<String, String>> _translations;
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    _featureRegistry = FeatureRegistry();
    _userDataNotifier = UserDataNotifier();
    _initializationFuture = _initializeApp();
  }

  Future<void> _initializeApp() async {
    _featureRegistry.addFeatures(widget.allFeatures);
    _featureRegistry.setDisabledFeatures(widget.disabledFeatureIds);
    _featureRegistry.setSelectedContributions(widget.selectedContributions);

    await _featureRegistry.initializeAll();

    // Aggregate translations from base + all features
    _translations = _featureRegistry.aggregateTranslations(baseTranslations);

    // Load the signed-in user (the login response carries no user object, only
    // id/token) so screens that need the current user id work after a restart.
    if (CacheManager.hasSession) {
      await UserSessionService.hydrate(_userDataNotifier);
    }
  }

  @override
  void dispose() {
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
    final scheme = ColorScheme.fromSeed(
      seedColor: ColorManager.lumiaAccent,
      brightness: Brightness.dark,
    ).copyWith(
      surface: ColorManager.lumiaBgDark,
      onSurface: ColorManager.lumiaTextPrimary,
      primary: ColorManager.lumiaAccent,
      onPrimary: ColorManager.white,
      primaryContainer: ColorManager.lumiaCardBorder,
      onPrimaryContainer: ColorManager.white,
      secondary: ColorManager.lumiaAccentLight,
      onSurfaceVariant: ColorManager.lumiaTextSecondary,
      outline: ColorManager.lumiaTextSecondary,
      error: ColorManager.error,
    );

    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: ColorManager.lumiaBgDark,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: ColorManager.lumiaBgDark,
        foregroundColor: ColorManager.lumiaTextPrimary,
      ),
      cardTheme: CardThemeData(
        color: ColorManager.lumiaCardBg,
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
                    title: AppConfig.production().appName,
                    debugShowCheckedModeBanner: false,
                    locale: localeNotifier.locale,
                    supportedLocales: localeNotifier.supportedLocales,
                    localizationsDelegates: [
                      AppLocalizationsDelegate(_translations),
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    // Dark-purple "lumia" theme applied to both slots so the
                    // look holds regardless of the light/dark toggle.
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
