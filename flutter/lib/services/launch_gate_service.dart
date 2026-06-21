import 'dart:io' show Platform;

import 'package:utd_app/cache/cache_manager.dart';
import 'package:utd_app/config/app_config.dart';
import 'package:utd_app/config/app_theme.dart';
import 'package:utd_app/network/network.dart';

/// One admin-managed contact link shown on the "Contact Us" screen.
///
/// [platform] is a known key (whatsapp, facebook, …) whose icon/color the app
/// supplies locally, or `custom` for an admin-defined link that ships its own
/// uploaded [icon] image and [color]. [label] is the display text and [value]
/// the raw url/handle the row opens.
class SocialLink {
  final String platform;
  final String label;
  final String value;
  final String? icon; // raw storage path (custom only); resolve before loading
  final String? color; // hex string e.g. "#1877F2"

  const SocialLink({
    required this.platform,
    required this.label,
    required this.value,
    this.icon,
    this.color,
  });

  factory SocialLink.fromJson(Map<String, dynamic> data) => SocialLink(
        platform: (data['platform'] as String?)?.trim() ?? 'custom',
        label: (data['label'] as String?)?.trim() ?? '',
        value: (data['value'] as String?)?.trim() ?? '',
        icon: (data['icon'] as String?)?.trim().isEmpty ?? true
            ? null
            : (data['icon'] as String).trim(),
        color: (data['color'] as String?)?.trim().isEmpty ?? true
            ? null
            : (data['color'] as String).trim(),
      );
}

/// Admin-managed branding returned by the launch bootstrap. Every field has a
/// safe default so the UI always has something to show.
class AppInfo {
  final String name;
  final String description;
  final String? logo; // raw storage path; resolve with resolveMediaUrl
  final String? supportEmail;
  final String? supportPhone;
  final String? privacyUrl;
  final String? termsUrl;

  /// Ordered admin-managed contact links (the new CRUD list). Empty when none
  /// are configured. The "Contact Us" screen renders these in order.
  final List<SocialLink> socialLinks;

  /// Legacy flat {platform: url/handle} map — kept for backward compatibility
  /// with older backends that don't emit [socialLinks] yet. Keys: whatsapp,
  /// website, facebook, instagram, twitter, youtube, tiktok, snapchat, telegram.
  final Map<String, String> social;

  const AppInfo({
    this.name = 'Tempo',
    this.description = '',
    this.logo,
    this.supportEmail,
    this.supportPhone,
    this.privacyUrl,
    this.termsUrl,
    this.socialLinks = const [],
    this.social = const {},
  });

  /// Default branding used before the bootstrap call returns (or if it fails).
  static const fallback = AppInfo();

  factory AppInfo.fromJson(Map<String, dynamic> data) {
    final name = (data['name'] as String?)?.trim();
    return AppInfo(
      name: (name == null || name.isEmpty) ? 'Tempo' : name,
      description: data['description'] as String? ?? '',
      logo: data['logo'] as String?,
      supportEmail: data['support_email'] as String?,
      supportPhone: data['support_phone'] as String?,
      privacyUrl: data['privacy_url'] as String?,
      termsUrl: data['terms_url'] as String?,
      socialLinks: (data['social_links'] is List)
          ? (data['social_links'] as List)
              .whereType<Map>()
              .map((e) => SocialLink.fromJson(Map<String, dynamic>.from(e)))
              .where((l) => l.value.isNotEmpty)
              .toList()
          : const [],
      social: (data['social'] is Map)
          ? (data['social'] as Map).map(
              (k, v) => MapEntry(k.toString(), v.toString()),
            )
          : const {},
    );
  }
}

/// App-wide access to the latest branding (set once the launch gate resolves).
/// Reads default [AppInfo.fallback] until then.
class AppInfoProvider {
  static AppInfo current = AppInfo.fallback;
}

/// Result of the launch-time platform check (force-update + maintenance + app).
class LaunchGateResult {
  final bool maintenance;
  final String? maintenanceMessage;
  final bool forceUpdate;
  final bool updateAvailable;
  final String? storeUrl;
  final AppInfo app;

  const LaunchGateResult({
    this.maintenance = false,
    this.maintenanceMessage,
    this.forceUpdate = false,
    this.updateAvailable = false,
    this.storeUrl,
    this.app = AppInfo.fallback,
  });

  /// Whether the app must show a blocking screen and refuse normal use.
  bool get blocks => maintenance || forceUpdate;

  /// Neutral result — nothing to block.
  static const none = LaunchGateResult();
}

/// Calls the public `/app-version` endpoint on launch to learn whether the
/// running build must be force-updated, the app is under maintenance, and to
/// pull admin-managed branding.
class LaunchGateService {
  /// Store/platform key sent to the backend. Huawei is indistinguishable from
  /// Android at runtime, so a Huawei build must pass `--dart-define=APP_STORE=huawei`.
  static String get _platform {
    const store = String.fromEnvironment('APP_STORE');
    if (store == 'huawei') return 'huawei';
    return Platform.isIOS ? 'ios' : 'android';
  }

  /// Apply the last cached branding + palette synchronously at startup, so the
  /// app shows the admin's colors/name instantly — before the network call, and
  /// even fully offline. Call once early in app init.
  static void loadCached() {
    final cached = CacheManager.getBootstrap();
    if (cached == null) return;
    final app = cached['app'];
    if (app is Map) {
      AppInfoProvider.current = AppInfo.fromJson(Map<String, dynamic>.from(app));
    }
    final theme = cached['theme'];
    if (theme is Map) {
      AppThemeProvider.current =
          AppPalette.fromJson(Map<String, dynamic>.from(theme));
    }
  }

  /// Fails open: any network/parse error returns [LaunchGateResult.none] so a
  /// backend hiccup never bricks the app on launch. Caches branding + palette
  /// into [AppInfoProvider] / [AppThemeProvider] and persists them for offline
  /// use, so a backend change is picked up here and refreshes the local cache.
  static Future<LaunchGateResult> check() async {
    try {
      final res = await ApiClient.instance.dio.get(
        '/app-version',
        queryParameters: {
          'platform': _platform,
          'version': appConfig.appBuildNumber,
        },
        options: Options(receiveTimeout: const Duration(seconds: 5)),
      );

      final body = res.data;
      final data = (body is Map) ? body['data'] : null;
      if (data is! Map) return LaunchGateResult.none;

      final appData = data['app'];
      final app = (appData is Map)
          ? AppInfo.fromJson(Map<String, dynamic>.from(appData))
          : AppInfo.fallback;
      AppInfoProvider.current = app;

      // Admin color palette (each field defaults to the built-in lumia value).
      final themeData = data['theme'];
      AppThemeProvider.current = (themeData is Map)
          ? AppPalette.fromJson(Map<String, dynamic>.from(themeData))
          : AppPalette.fallback;

      // Persist branding + palette so the next launch applies them instantly and
      // offline. Overwrites the cache, so an admin change is picked up here.
      await CacheManager.saveBootstrap({
        if (appData is Map) 'app': Map<String, dynamic>.from(appData),
        if (themeData is Map) 'theme': Map<String, dynamic>.from(themeData),
      });

      return LaunchGateResult(
        maintenance: data['maintenance'] == true,
        maintenanceMessage: data['maintenance_message'] as String?,
        forceUpdate: data['force_update'] == true,
        updateAvailable: data['update_available'] == true,
        storeUrl: data['store_url'] as String?,
        app: app,
      );
    } catch (_) {
      return LaunchGateResult.none;
    }
  }
}
