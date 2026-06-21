import 'package:hive_flutter/hive_flutter.dart';
import 'package:utd_app/cache/cache_manager.dart';
import 'package:utd_studio_sdk/utd_studio_sdk.dart';

/// [KeyValueCache] backed by Hive. Server-driven screen JSON lives in its own
/// `stac_screens` box (preserving the original `v_`/`d_` keys, so screens cached
/// by the pre-package build keep working); the user/appConfig blobs delegate to
/// the app's [CacheManager].
class HiveKeyValueCache implements KeyValueCache {
  HiveKeyValueCache._(this._screens);

  final Box _screens;

  static const String _screensBoxName = 'stac_screens';

  /// Opens the screen-cache box. Call once during bootstrap BEFORE
  /// `UtdStudio.init`, because [getString] (used by `getScreenCached`) is
  /// synchronous and needs the box already open.
  static Future<HiveKeyValueCache> open() async =>
      HiveKeyValueCache._(await Hive.openBox(_screensBoxName));

  // Namespaced string store. Today the only namespace is `stac_screens`, which
  // maps to the dedicated box above.
  @override
  String? getString(String namespace, String key) => _screens.get(key) as String?;

  @override
  Future<void> putString(String namespace, String key, String value) =>
      _screens.put(key, value);

  @override
  Future<void> deleteKey(String namespace, String key) => _screens.delete(key);

  @override
  bool containsKey(String namespace, String key) => _screens.containsKey(key);

  // JSON blobs delegate to the app cache (the `utd_cache` box).
  @override
  Map<String, dynamic>? getUserData() => CacheManager.getUserData();

  @override
  Future<void> saveUserData(Map<String, dynamic> json) =>
      CacheManager.saveUserData(json);

  @override
  Map<String, dynamic>? getAppConfig() => CacheManager.getAppConfig();

  @override
  Future<void> saveAppConfig(Map<String, dynamic> json) =>
      CacheManager.saveAppConfig(json);
}
