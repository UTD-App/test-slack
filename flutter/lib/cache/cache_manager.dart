import 'package:hive_flutter/hive_flutter.dart';

class CacheManager {
  static const String _boxName = 'utd_cache';
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  static late Box _box;

  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  // ── Token ────────────────────────────────────────────────────────────────

  static Future<void> saveToken(String token) => _box.put(_tokenKey, token);

  static String? getToken() => _box.get(_tokenKey) as String?;

  // ── User data ─────────────────────────────────────────────────────────────

  static Future<void> saveUserData(Map<String, dynamic> json) {
    return _box.put(_userKey, json);
  }

  static Map<String, dynamic>? getUserData() {
    final raw = _box.get(_userKey);
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw as Map);
  }

  // ── Feature settings ──────────────────────────────────────────────────────

  static const String _disabledFeaturesKey = 'disabled_features';
  static const String _selectedContributionsKey = 'selected_contributions';
  static const String _enabledPackagesKey = 'enabled_packages';

  static Future<void> saveDisabledFeatures(List<String> featureIds) =>
      _box.put(_disabledFeaturesKey, featureIds);

  static List<String> getDisabledFeatures() {
    final raw = _box.get(_disabledFeaturesKey);
    if (raw == null) return [];
    return List<String>.from(raw as List);
  }

  /// Backend-reported enabled package slugs (from `GET /packages/installed`),
  /// cached so the launch-time package gate can apply them instantly/offline.
  /// Returns null when never fetched ("unknown" — gate fails open, disables
  /// nothing) vs an empty list ("known: nothing enabled").
  static Future<void> saveEnabledPackages(List<String> slugs) =>
      _box.put(_enabledPackagesKey, slugs);

  static List<String>? getEnabledPackages() {
    final raw = _box.get(_enabledPackagesKey);
    if (raw == null) return null;
    return List<String>.from(raw as List);
  }

  static Future<void> saveSelectedContributions(
    Map<String, String> selections,
  ) =>
      _box.put(_selectedContributionsKey, selections);

  static Map<String, String> getSelectedContributions() {
    final raw = _box.get(_selectedContributionsKey);
    if (raw == null) return {};
    return Map<String, String>.from(raw as Map);
  }

  // ── Launch bootstrap (branding + colors) ───────────────────────────────────
  // Cache the admin-managed branding/theme from /app-version so the next launch
  // applies them instantly (and offline), and refreshes in the background.

  static const String _bootstrapKey = 'launch_bootstrap';

  static Future<void> saveBootstrap(Map<String, dynamic> data) =>
      _box.put(_bootstrapKey, data);

  static Map<String, dynamic>? getBootstrap() {
    final raw = _box.get(_bootstrapKey);
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw as Map);
  }

  // ── App config (branding) ──────────────────────────────────────────────────
  // Cached app-level config (app_logo / app_name / …) fetched from /configs, so
  // the server-driven splash can resolve `core.app` bindings offline on warm
  // launches. Set by the base/web admin; the Studio only reads the attributes.

  static const String _appConfigKey = 'app_config';

  static Future<void> saveAppConfig(Map<String, dynamic> json) =>
      _box.put(_appConfigKey, json);

  static Map<String, dynamic>? getAppConfig() {
    final raw = _box.get(_appConfigKey);
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw as Map);
  }

  // ── Generic flags ─────────────────────────────────────────────────────────
  // Small bool flags for packages that gate UI on a startup capability check
  // (e.g. Gifts caches whether a Wallet package is installed) so a transient
  // network failure doesn't flip that UI off on the next launch.

  static Future<void> saveFlag(String key, bool value) => _box.put(key, value);

  static bool? getFlag(String key) => _box.get(key) as bool?;

  // ── Session helpers ───────────────────────────────────────────────────────

  static bool get hasSession => getToken() != null;

  static Future<void> clear() => _box.clear();
}
