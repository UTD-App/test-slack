import 'package:utd_app/cache/cache_manager.dart';
import 'package:utd_app/network/network.dart';

import 'stac_data_registry.dart';

/// Wires the base app's CORE data into the Stac renderer.
///
/// Mirrors `registerChatStacSources` (chat package) but for the screens that
/// ship inside the base app. Currently exposes the signed-in user as the
/// single-object source `core.currentUser`, consumed by a `utdObject` on the
/// profile screen. Keys MUST match the `core` manifest elements
/// (backend/config/utd_manifest_core.php → name/email/bio/avatar).
///
/// Pulls fresh data from `/my-data` (which now returns a ready-to-display
/// `avatar` URL) and refreshes the cache, so the profile screen shows the real
/// photo on first open. Falls back to the cached payload when offline.
void registerCoreStacSources() {
  StacDataRegistry.instance.registerObject('core.currentUser', () async {
    try {
      final res = await ApiClient.instance.dio.get('/my-data');
      final data = res.data is Map ? (res.data['data'] as Map?) : null;
      if (data != null) {
        await CacheManager.saveUserData({
          ...?CacheManager.getUserData(),
          ...Map<String, dynamic>.from(data),
        });
      }
    } catch (_) {
      // أوفلاين/خطأ → نكمّل بالبيانات المخزّنة.
    }

    final user = CacheManager.getUserData() ?? const <String, dynamic>{};
    final covers = user['covers'];
    return {
      'name': user['name'] ?? '',
      'email': user['email'] ?? '',
      'bio': user['bio'] ?? '',
      'avatar': user['avatar'] ?? user['image'] ?? '',
      // Extra fields so the profile screen can mirror the real design. Resolved
      // defensively from whatever /my-data returns; missing → '' (the manifest
      // hides them via visibleBinding). Keys MUST match the core manifest
      // object_source `core.currentUser`.
      'cover': (covers is List && covers.isNotEmpty)
          ? covers.first.toString()
          : (user['cover']?.toString() ?? ''),
      'country': user['country_name'] ?? user['country'] ?? '',
      'flag': user['country_flag'] ?? user['flag'] ?? '',
      'uid': user['uuid']?.toString() ??
          user['uid']?.toString() ??
          user['id']?.toString() ??
          '',
    };
  });
}
