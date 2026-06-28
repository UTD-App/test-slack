import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

/// Disk cache (Hive) for the moments feed's first page, so the tab paints the
/// last-seen feed instantly on open (no spinner) and works offline, while the
/// network refreshes it in the background.
///
/// Entries are stored as JSON **strings** (not raw maps): Hive hands back
/// `Map<dynamic, dynamic>` for nested objects, which would break the model's
/// `Map<String, dynamic>` casts (e.g. a moment's `user`); `jsonDecode` yields
/// correctly-typed maps, sidestepping that trap entirely.
class MomentFeedCache {
  static const String _boxName = 'utd_moment_cache';

  Box? _box;

  Future<Box> _openBox() async {
    // Hive.initFlutter() already ran at startup (CacheManager.init); just open.
    return _box ??= await Hive.openBox(_boxName);
  }

  String _key(int type, int? userId) => 'feed:$type:${userId ?? 'all'}';

  /// Persist the first page's raw moment maps for (type, userId). Best-effort:
  /// a cache write must never break the feed.
  Future<void> save(
    int type,
    int? userId,
    List<Map<String, dynamic>> moments,
  ) async {
    try {
      final box = await _openBox();
      await box.put(_key(type, userId), jsonEncode(moments));
    } catch (_) {
      // ignore — caching is an optimisation, not a requirement.
    }
  }

  /// The cached first page for (type, userId), or empty when nothing is stored.
  Future<List<Map<String, dynamic>>> load(int type, int? userId) async {
    try {
      final box = await _openBox();
      final raw = box.get(_key(type, userId));
      if (raw is! String || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
