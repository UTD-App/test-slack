import 'package:authentication/authentication.dart';
import 'package:profile/profile.dart';
import 'package:audio_room/audio_room.dart';
import 'package:moment/moment.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:utd_app/cache/cache_manager.dart';
import 'package:utd_app/config/theme_notifier.dart';
import 'package:utd_app/services/firebase_service.dart';
import 'package:utd_app/services/notification_service.dart';
import 'package:utd_app/shared/services/translation_service.dart';
import 'package:utd_app/shared/stac/parsers/self_profile_card_parser.dart';

import 'addons/app_feature.dart';
import 'app.dart';
import 'config/app_config.dart';
import 'config/app_layout_service.dart';
import 'features/notifications/notifications_feature.dart';
import 'localization/localization.dart';
import 'network/network.dart';
import 'studio_glue/studio_bootstrap.dart';
import 'shared/media/app_cache_manager.dart';

final _restartNotifier = ValueNotifier<int>(0);

void restartApp() {
  _restartNotifier.value++;
}

// عائلات الخطوط المنسّقة (Google Fonts) — لازم تطابق FONTS في الـ Studio.
// Stac بيمرّر textStyle.fontFamily كاسم نصّي خام لـ TextStyle، وده مايشغّلش
// google_fonts لوحده — فلازم نطلب كل عائلة/وزن مرة عشان يتسجّل تحت اسمه العادي
// (مثلاً 'Cairo') ويُحَلّ الاسم النصّي وقت الرندر. fire-and-forget، يتكاش على القرص.
const _kStudioFontFamilies = [
  'Cairo', 'Tajawal', 'Almarai', 'IBM Plex Sans Arabic', 'Changa',
  'Inter', 'Poppins', 'Roboto', 'Montserrat', 'Lora',
];

void _preloadStudioFonts() {
  const weights = [
    FontWeight.w400, FontWeight.w500, FontWeight.w600, FontWeight.w700,
  ];
  GoogleFonts.pendingFonts([
    for (final family in _kStudioFontFamilies)
      for (final w in weights) GoogleFonts.getFont(family, fontWeight: w),
  ]);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FirebaseService.initialize();
  await CacheManager.init();
  AppCacheManager.instance.init();

  // Build features once up-front so packages can contribute custom Stac
  // widget/action parsers. (Parsers are stateless and resolve their deps from
  // context at parse time, so building here — before feature.initialize() — is
  // safe.) The widget tree builds its own feature instances below.
  List<AppFeature> buildFeatures() {
    // Add your purchased packages here — see README for instructions
    return [
      AuthFeature(),
      NotificationsFeature(),
      ProfileFeature(),
      MomentFeature(),
      AudioRoomFeature(),
    ];
  }

  final parserFeatures = buildFeatures();
  final featureParsers = [for (final f in parserFeatures) ...f.getStacParsers()];
  final featureActionParsers = [
    for (final f in parserFeatures) ...f.getStacActionParsers(),
  ];

  // Initialize Translation service
  await TranslationService.instance.init();

  // Production server at project-x.utdsoftware.com (baseUrl https://project-x.utdsoftware.com/api).
  final config = AppConfig.production();
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

  // Boot UTD Studio (server-driven UI) now that the API client is ready:
  // UtdStudio.init runs Stac.initialize → screen-store init → background sync,
  // then registers the base's core data sources (core.currentUser + core.app).
  // featureParsers includes the test-specific SelfProfileCardParser. Must
  // precede AppLayoutService (reads a server-driven document) and runApp.
  await bootstrapStudio(
    themeNotifier: themeNotifier,
    localeNotifier: localeNotifier,
    featureParsers: [const SelfProfileCardParser(), ...featureParsers],
    featureActionParsers: featureActionParsers,
  );

  // Apply the server-delivered app layout (flow + bottom nav) BEFORE runApp so
  // the router guard, boot resolver and home shell all read the customer flow.
  // Cache-backed + short-timeout → no startup hang; falls back to AppFlow.fallback.
  await AppLayoutService.instance.applyIfPresent();

  // Sync translations in background (Stac screens already sync inside
  // bootstrapStudio → UtdStudio.init).
  TranslationService.instance.sync(localeNotifier.locale.languageCode);

  // Preload curated Google Fonts so server-driven screens that set a custom
  // textStyle.fontFamily render the real font (non-blocking; cached on disk).
  _preloadStudioFonts();

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
