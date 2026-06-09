import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:utd_app/network/client/api_client.dart';

/// Stac server-driven UI service.
/// Screens are cached permanently — re-fetched only when version changes.
///
/// Developer workflow:
/// 1. Write screen using Stac DSL in Dart
/// 2. Generate JSON using Stac CLI
/// 3. Upload JSON to admin panel
/// 4. Flutter fetches and renders — no App Store update needed
///
/// Usage from any package:
///   final json = await StacService.instance.getScreen('gift_popup');
///   if (json != null) Stac.fromJson(json);
class StacService {
  static final StacService instance = StacService._();
  StacService._();

  static const String _boxName = 'stac_screens';
  static const String _versionPrefix = 'v_';
  static const String _dataPrefix = 'd_';

  Box? _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  /// Sync all screens — checks versions and fetches only changed ones.
  /// Call this on app startup.
  Future<void> syncAll() async {
    try {
      final response = await ApiClient.instance.dio.get('/stac');
      final screens  = response.data['data'] as List<dynamic>? ?? [];

      await Future.wait(
        screens.map((s) => _syncScreen(s['name'] as String, s['version'] as String)),
      );
    } catch (_) {
      // Network error — use cached screens
    }
  }

  /// Get a screen's JSON content by name.
  /// Returns null if screen not found locally.
  Future<Map<String, dynamic>?> getScreen(String name) async {
    try {
      await _syncSingleIfNeeded(name);
    } catch (_) {}

    final raw = _box?.get('$_dataPrefix$name') as String?;
    if (raw == null) return null;

    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Cache-only read (no network). For startup paths that must not block on a
  /// slow/unreachable base — returns the last cached content or null.
  Map<String, dynamic>? getScreenCached(String name) {
    final raw = _box?.get('$_dataPrefix$name') as String?;
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Check if a screen exists locally.
  bool hasScreen(String name) {
    return _box?.containsKey('$_dataPrefix$name') == true;
  }

  /// Force re-fetch a screen from server.
  Future<void> invalidate(String name) async {
    await _box?.delete('$_versionPrefix$name');
    await _syncSingleIfNeeded(name);
  }

  Future<void> _syncScreen(String name, String serverVersion) async {
    final localVersion = _box?.get('$_versionPrefix$name') as String?;
    if (localVersion == serverVersion) return;

    await _fetchAndStore(name);
  }

  Future<void> _syncSingleIfNeeded(String name) async {
    try {
      final response = await ApiClient.instance.dio.get('/stac/$name/version');
      final serverVersion = response.data['data']?['version'] as String?;
      final localVersion  = _box?.get('$_versionPrefix$name') as String?;

      if (serverVersion != null && serverVersion != localVersion) {
        await _fetchAndStore(name);
      }
    } catch (_) {}
  }

  Future<void> _fetchAndStore(String name) async {
    try {
      final response = await ApiClient.instance.dio.get('/stac/$name');
      final data = response.data['data'] as Map<String, dynamic>?;
      if (data == null) return;

      await _box?.put('$_dataPrefix$name', jsonEncode(data['content']));
      await _box?.put('$_versionPrefix$name', data['version'] as String);
    } catch (_) {}
  }
}
