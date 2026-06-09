import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Server-side API response cache with configurable TTL.
/// Used for data that changes occasionally (not permanent like media files).
///
/// Usage from any package:
///   final data = await ApiCacheService.instance.get('gifts_list', ttl: Duration(minutes: 10));
///   await ApiCacheService.instance.set('gifts_list', jsonData);
///   await ApiCacheService.instance.invalidate('gifts_list');
class ApiCacheService {
  static final ApiCacheService instance = ApiCacheService._();
  ApiCacheService._();

  static const String _prefix = 'api_cache_';
  static const String _tsPrefix = 'api_cache_ts_';

  /// Get cached data for a key. Returns null if expired or not found.
  Future<Map<String, dynamic>?> get(
    String key, {
    Duration ttl = const Duration(minutes: 15),
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final tsKey = '$_tsPrefix$key';
    final dataKey = '$_prefix$key';

    final timestamp = prefs.getInt(tsKey);
    if (timestamp == null) return null;

    final age = DateTime.now().millisecondsSinceEpoch - timestamp;
    if (age > ttl.inMilliseconds) {
      await _remove(prefs, key);
      return null;
    }

    final raw = prefs.getString(dataKey);
    if (raw == null) return null;

    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Get cached list data.
  Future<List<dynamic>?> getList(
    String key, {
    Duration ttl = const Duration(minutes: 15),
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final tsKey = '$_tsPrefix$key';
    final dataKey = '$_prefix$key';

    final timestamp = prefs.getInt(tsKey);
    if (timestamp == null) return null;

    final age = DateTime.now().millisecondsSinceEpoch - timestamp;
    if (age > ttl.inMilliseconds) {
      await _remove(prefs, key);
      return null;
    }

    final raw = prefs.getString(dataKey);
    if (raw == null) return null;

    try {
      return jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Save data to cache.
  Future<void> set(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$key', jsonEncode(data));
    await prefs.setInt('$_tsPrefix$key', DateTime.now().millisecondsSinceEpoch);
  }

  /// Remove a specific cache entry.
  Future<void> invalidate(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await _remove(prefs, key);
  }

  /// Clear all API cache entries.
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where(
      (k) => k.startsWith(_prefix) || k.startsWith(_tsPrefix),
    );
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  Future<void> _remove(SharedPreferences prefs, String key) async {
    await prefs.remove('$_prefix$key');
    await prefs.remove('$_tsPrefix$key');
  }
}
