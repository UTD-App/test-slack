import 'dart:async';
import 'dart:developer' as developer;

import 'package:audio_room/audio_room.dart';
import 'package:audio_room_charisma/audio_room_charisma.dart';
import 'package:audio_room_mode_seats12/audio_room_mode_seats12.dart';
import 'package:audio_room_mode_seats22/audio_room_mode_seats22.dart';
import 'package:authentication/authentication.dart';
import 'package:device_preview/device_preview.dart';
import 'package:gifts/gifts.dart';
import 'package:profile/profile.dart';
import 'package:wallet/wallet.dart';
import 'package:moment/moment.dart';
import 'package:reels/reels.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:utd_app/cache/cache_manager.dart';
import 'package:utd_app/shared/core/system_ui_style.dart';
import 'package:utd_app/config/theme_notifier.dart';
import 'package:utd_app/services/firebase_service.dart';
import 'package:utd_app/services/notification_service.dart';
import 'package:utd_app/shared/services/translation_service.dart';
import 'package:utd_app/shared/stac/parsers/self_profile_card_parser.dart';
import 'package:utd_app/shared/stac/parsers/edit_profile_form_parser.dart';

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

void main() {
  // Run the whole app inside a guarded zone so async errors that escape a
  // widget (the common cause of a silent freeze / red screen in release) are
  // captured instead of lost.
  runZonedGuarded<Future<void>>(_startApp, (error, stack) {
    _reportError(error, stack, fatal: true);
  });
}

/// Single crash sink. Logs everywhere; in release this is the one place to
/// forward to a crash reporter (e.g. FirebaseCrashlytics.instance.recordError).
void _reportError(Object error, StackTrace? stack, {bool fatal = false}) {
  developer.log(
    'Uncaught${fatal ? ' (fatal)' : ''} error: $error',
    name: 'utd_app',
    error: error,
    stackTrace: stack,
  );
}

Future<void> _startApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Route framework + platform-dispatcher errors through the same sink so they
  // are never swallowed silently.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    _reportError(details.exception, details.stack, fatal: true);
  };
  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    _reportError(error, stack, fatal: true);
    return true;
  };

  // Edge-to-edge: draw behind both system bars and keep them transparent with
  // light icons over the dark purple gradient (re-asserted on every AppBar via
  // appBarTheme.systemOverlayStyle). Without this Android paints opaque black
  // bars top & bottom. See [kTransparentLightSystemUi].
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(kTransparentLightSystemUi);

  await FirebaseService.initialize();
  await CacheManager.init();
  AppCacheManager.instance.init();

  // Create AudioRoomFeature once and register plugins on it so the same
  // instance (with plugins attached) is reused across buildFeatures() calls.
  final audioRoom = AudioRoomFeature();
  audioRoom.registerPlugin(CharismaPlugin());
  audioRoom.registerModePlugin(Seats12ModePlugin());
  audioRoom.registerModePlugin(Seats22ModePlugin());

  List<AppFeature> buildFeatures() {
    return [
      AuthFeature(),
      GiftsFeature(),
      NotificationsFeature(),
      ProfileFeature(),
      WalletFeature(),
      MomentFeature(),
      ReelsFeature(),
      audioRoom,
    ];
  }

  final parserFeatures = buildFeatures();
  final featureParsers = [
    for (final f in parserFeatures) ...f.getStacParsers(),
  ];
  final featureActionParsers = [
    for (final f in parserFeatures) ...f.getStacActionParsers(),
  ];

  // Initialize Translation service
  await TranslationService.instance.init();

  // Production server at project-x.utdsoftware.com (baseUrl https://project-x.utdsoftware.com/api).
  final config = AppConfig.production();
  AppConfigProvider.initialize(config);

  // Languages come from the backend (the admin "Languages" resource). Use the
  // cached list for an instant first paint; it's refreshed in the background
  // below so a newly added language appears without a relaunch. The en/ar seed
  // covers the very first run before any fetch.
  final supportedLanguages =
      TranslationService.instance.cachedSupportedLanguages();
  final supportedLocales = supportedLanguages
      .map((e) => Locale(e['code'] as String))
      .toList();
  final rtlCodes = supportedLanguages
      .where((e) => e['is_rtl'] == true)
      .map((e) => e['code'] as String)
      .toSet();
  Map<String, String> namesOf(List<Map<String, dynamic>> langs) => {
        for (final e in langs)
          (e['code'] as String): (e['native_name'] as String? ?? e['code'] as String),
      };

  final localeNotifier = LocaleNotifier();
  await localeNotifier.initialize(
    supportedLocales: supportedLocales.isNotEmpty
        ? supportedLocales
        : const [Locale('en'), Locale('ar')],
    fallbackLocale: const Locale('en'),
    useDeviceLocale: config.useDeviceLocale,
    rtlCodes: rtlCodes.isNotEmpty ? rtlCodes : const {'ar'},
    names: namesOf(supportedLanguages),
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
    featureParsers: [
      const SelfProfileCardParser(),
      const EditProfileFormParser(),
      ...featureParsers,
    ],
    featureActionParsers: featureActionParsers,
  );

  // Apply the server-delivered app layout (flow + bottom nav) BEFORE runApp so
  // the router guard, boot resolver and home shell all read the customer flow.
  // Cache-backed + short-timeout → no startup hang; falls back to AppFlow.fallback.
  await AppLayoutService.instance.applyIfPresent();

  // Tell the backend which language to localize responses in (notifications are
  // rendered on read in this locale; device-token registration stores it for
  // push). LocaleNotifier keeps it in sync on every later language switch.
  ApiClient.instance.setHeader(
    'X-localization',
    localeNotifier.locale.languageCode,
  );

  // Sync translations in background (Stac screens already sync inside
  // bootstrapStudio → UtdStudio.init).
  TranslationService.instance.sync(localeNotifier.locale.languageCode);
  // Refresh the supported-language list from the backend and apply it live, so a
  // language added in the admin appears without waiting for a relaunch.
  TranslationService.instance.fetchSupportedLanguages().then((langs) {
    if (langs.isEmpty) return;
    localeNotifier.applySupported(
      langs.map((e) => Locale(e['code'] as String)).toList(),
      rtlCodes:
          langs.where((e) => e['is_rtl'] == true).map((e) => e['code'] as String).toSet(),
      names: namesOf(langs),
    );
  });

  // Preload curated Google Fonts so server-driven screens that set a custom
  // textStyle.fontFamily render the real font (non-blocking; cached on disk).
  _preloadStudioFonts();

  runApp(
    DevicePreview(
      // Dev-only inspector chrome; must never wrap the production app.
      enabled: !kReleaseMode,
      builder: (_) => ValueListenableBuilder<int>(
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
    ),
  );
}
