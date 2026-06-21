import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:utd_app/network/client/api_client.dart';

/// Permanent translation cache with server version-based invalidation.
///
/// Flow:
/// 1. App launch → check /translations/{locale}/version (tiny request)
/// 2. If version matches local → use Hive cache (no network call)
/// 3. If version differs   → fetch /translations/{locale} → update Hive
///
/// Admin changes a key → server version bumps → next app launch re-fetches.
class TranslationService {
  static final TranslationService instance = TranslationService._();
  TranslationService._();

  static const String _boxName = 'translations';
  static const String _versionPrefix = 'version_';
  static const String _dataPrefix = 'data_';
  static const String _supportedKey = 'supported_languages';

  /// Offline seed used before the first successful fetch.
  static const List<Map<String, dynamic>> _seedLanguages = [
    {'code': 'en', 'native_name': 'English', 'is_rtl': false},
    {'code': 'ar', 'native_name': 'العربية', 'is_rtl': true},
  ];

  Box? _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  /// Call on app start. Fetches translations if version changed.
  Future<void> sync(String locale) async {
    try {
      final serverVersion = await _fetchVersion(locale);
      final localVersion  = _box?.get('$_versionPrefix$locale') as String?;

      if (serverVersion != null && serverVersion == localVersion) return;

      final data = await _fetchAll(locale);
      if (data != null) {
        await _box?.put('$_dataPrefix$locale', jsonEncode(data['translations']));
        await _box?.put('$_versionPrefix$locale', data['version'] as String);
      }
    } catch (_) {
      // Network error — use cached data silently
    }
  }

  /// Get a translation value. Falls back to the key itself if not found.
  String get(String locale, String key) {
    final raw = _box?.get('$_dataPrefix$locale') as String?;
    if (raw == null) return key;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map[key] as String? ?? key;
    } catch (_) {
      return key;
    }
  }

  /// Fetch the backend's active languages and cache them (for the NEXT launch).
  /// Best-effort: returns the cached list on any failure. Call in the background
  /// after the API client is ready (like [sync]).
  Future<List<Map<String, dynamic>>> fetchSupportedLanguages() async {
    try {
      final response =
          await ApiClient.instance.dio.get('/translations/supported');
      final data = response.data['data'];
      if (data is List) {
        final list = data
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
        if (list.isNotEmpty) {
          await _box?.put(_supportedKey, jsonEncode(list));
          return list;
        }
      }
    } catch (_) {
      // Network error — fall back to whatever is cached.
    }
    return cachedSupportedLanguages();
  }

  /// The cached active languages (synchronous; safe before the API is ready).
  /// Falls back to the en/ar seed on first launch. Each entry has
  /// `code`, `native_name`, `is_rtl`.
  List<Map<String, dynamic>> cachedSupportedLanguages() {
    final raw = _box?.get(_supportedKey) as String?;
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        final parsed = list
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
        if (parsed.isNotEmpty) return parsed;
      } catch (_) {
        // Corrupt cache — fall through to the seed.
      }
    }
    return _seedLanguages;
  }

  /// Get all translations for a locale as a map.
  Map<String, String> getAll(String locale) {
    final raw = _box?.get('$_dataPrefix$locale') as String?;
    if (raw == null) return {};

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return {};
    }
  }

  Future<String?> _fetchVersion(String locale) async {
    try {
      final response = await ApiClient.instance.dio.get(
        '/translations/$locale/version',
      );
      return response.data['data']?['version'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetchAll(String locale) async {
    try {
      final response = await ApiClient.instance.dio.get('/translations/$locale');
      return response.data['data'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }
}
