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

  static Future<void> saveDisabledFeatures(List<String> featureIds) =>
      _box.put(_disabledFeaturesKey, featureIds);

  static List<String> getDisabledFeatures() {
    final raw = _box.get(_disabledFeaturesKey);
    if (raw == null) return [];
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

  // ── "Seen once" flags ──────────────────────────────────────────────────────
  // Generic per-key flags backing `showOnce` screens (intro/landing, etc.). The
  // key is the screen's stable route — never its display name — so renaming a
  // screen in Studio doesn't make it reappear.

  static const String _seenPrefix = 'seen:';

  static bool seen(String key) =>
      _box.get('$_seenPrefix$key', defaultValue: false) as bool;

  static Future<void> markSeen(String key) =>
      _box.put('$_seenPrefix$key', true);

  // ── Session helpers ───────────────────────────────────────────────────────

  static bool get hasSession => getToken() != null;

  /// Clears session data on logout. PRESERVES every `seen:` flag so logging out
  /// is not mistaken for a fresh install — a `showOnce` screen (e.g. the intro)
  /// stays seen across logout, only ever shown on a true first run.
  static Future<void> clear() async {
    final seenKeys =
        _box.keys.where((k) => k.toString().startsWith(_seenPrefix)).toList();
    final preserved = {for (final k in seenKeys) k: _box.get(k)};
    await _box.clear();
    if (preserved.isNotEmpty) await _box.putAll(preserved);
  }
}
