import 'package:authentication/authentication.dart';
import 'package:audio_room/audio_room.dart';
import 'package:moment/moment.dart';
import 'package:flutter/material.dart';
import 'package:stac/stac.dart' hide StacService;
import 'package:utd_app/cache/cache_manager.dart';
import 'package:utd_app/config/theme_notifier.dart';
import 'package:utd_app/services/firebase_service.dart';
import 'package:utd_app/services/notification_service.dart';
import 'package:utd_app/shared/services/stac_service.dart';
import 'package:utd_app/shared/services/translation_service.dart';
import 'package:utd_app/shared/stac/actions/core_actions.dart';
import 'package:utd_app/shared/stac/core_stac_sources.dart';
import 'package:utd_app/shared/stac/parsers/stac_list_parser.dart';
import 'package:utd_app/shared/stac/parsers/stac_object_parser.dart';
import 'package:utd_app/shared/stac/parsers/utd_text_field_parser.dart';
import 'package:utd_app/shared/stac/parsers/utd_sized_parser.dart';

import 'addons/app_feature.dart';
import 'app.dart';
import 'config/app_config.dart';
import 'config/app_layout_service.dart';
import 'localization/localization.dart';
import 'network/network.dart';
import 'shared/media/app_cache_manager.dart';

final _restartNotifier = ValueNotifier<int>(0);

void restartApp() {
  _restartNotifier.value++;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FirebaseService.initialize();
  await CacheManager.init();
  AppCacheManager.instance.init();

  // Build features once up-front so packages can contribute custom Stac
  // widget/action parsers to Stac.initialize. (Parsers are stateless and
  // resolve their deps from context at parse time, so building here — before
  // feature.initialize() — is safe.) The widget tree builds its own feature
  // instances below for providers/routes.
  List<AppFeature> buildFeatures() {
    // Add your purchased packages here — see README for instructions
    return [
      AuthFeature(),
      MomentFeature(),
      AudioRoomFeature(),
    ];
  }

  final parserFeatures = buildFeatures();
  final featureParsers = [for (final f in parserFeatures) ...f.getStacParsers()];
  final featureActionParsers = [
    for (final f in parserFeatures) ...f.getStacActionParsers(),
  ];

  // Initialize Stac server-driven UI + UTD custom parsers (data-bound list +
  // single-object) + package-contributed parsers, and the core actions.
  await Stac.initialize(
    parsers: [
      const StacUtdListParser(),
      const StacUtdObjectParser(),
      const StacUtdTextFieldParser(),
      const StacUtdSizedParser(),
      ...featureParsers,
    ],
    actionParsers: [...coreStacActionParsers, ...featureActionParsers],
  );
  await StacService.instance.init();

  // Register the base app's own core data sources (e.g. core.currentUser).
  registerCoreStacSources();

  // Initialize Translation service
  await TranslationService.instance.init();

  final config = AppConfig.development();
  AppConfigProvider.initialize(config);

  final localeNotifier = LocaleNotifier();
  await localeNotifier.initialize(
    supportedLocales: const [Locale('en'), Locale('ar')],
    fallbackLocale: const Locale('en'),
    useDeviceLocale: config.useDeviceLocale,
  );

  final themeNotifier = ThemeNotifier();
  await themeNotifier.initialize();

  if (FirebaseService.isInitialized) {
    await NotificationService().initialize();
  }

  ApiClient.initialize(
    ApiClientConfig(
      baseUrl: config.baseUrl,
      connectTimeout: config.apiTimeout,
      receiveTimeout: config.apiTimeout,
      enableLogging: true,
      enableRetry: true,
      maxRetries: config.maxRetryAttempts,
      getToken: () async => CacheManager.getToken(),
      onTokenExpired: () async => null,
      onLogout: () async {
        await CacheManager.clear();
      },
    ),
  );

  // Apply the server-delivered app layout (flow + bottom nav) BEFORE runApp so
  // the router guard, boot resolver and home shell all read the customer flow.
  // Cache-backed + short-timeout → no startup hang; falls back to AppFlow.fallback.
  await AppLayoutService.instance.applyIfPresent();

  // Sync Stac screens and translations in background after API is ready
  StacService.instance.syncAll();
  TranslationService.instance.sync(localeNotifier.locale.languageCode);

  runApp(
    ValueListenableBuilder<int>(
      valueListenable: _restartNotifier,
      builder: (_, restartCount, __) {
        final disabledIds = CacheManager.getDisabledFeatures().toSet();
        final selectedContributions = CacheManager.getSelectedContributions();
        final allFeatures = buildFeatures();

        return AddonPlatformApp(
          key: ValueKey(restartCount),
          allFeatures: allFeatures,
          disabledFeatureIds: disabledIds,
          selectedContributions: selectedContributions,
          localeNotifier: localeNotifier,
          themeNotifier: themeNotifier,
        );
      },
    ),
  );
}
