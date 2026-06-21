import 'package:utd_app/cache/cache_manager.dart';
import 'package:utd_app/network/network.dart';

/// Learns which backend packages are enabled, so the app can mirror an admin's
/// dashboard enable/disable onto its locally-compiled features.
///
/// The backend is the source of truth: when a package is disabled there, its
/// routes/migrations stop loading ([PackageRegistry::isEnabled]). Without this
/// gate the Flutter app would keep the package's feature registered and call its
/// now-missing routes (404). [App] reads [sync] at launch and auto-disables any
/// feature whose [AppFeature.packageSlug] is absent from the enabled set, so the
/// app behaves exactly as if that package weren't installed.
///
/// Mirrors [LaunchGateService]: fail-open, cache-first, never bricks the app.
class PackageGateService {
  PackageGateService._();

  /// Calls the public `GET /packages/installed` endpoint and returns the set of
  /// enabled package slugs (always includes `base`). Persists the list for an
  /// instant/offline read on the next launch.
  ///
  /// Fail-open contract:
  /// - network/parse error → returns the last cached set (or `null` if none),
  /// - never fetched and no cache → returns `null` = "unknown", so the caller
  ///   disables nothing (a network blip must never hide a paid package). This
  ///   matches the backend's "absent row ⇒ enabled" semantics.
  static Future<Set<String>?> sync() async {
    try {
      final res = await ApiClient.instance.dio.get(
        '/packages/installed',
        options: Options(receiveTimeout: const Duration(seconds: 5)),
      );

      final body = res.data;
      final data = (body is Map) ? body['data'] : null;
      final packages = (data is Map) ? data['packages'] : null;
      if (packages is! List) return _cached();

      final slugs = packages
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList(growable: false);

      await CacheManager.saveEnabledPackages(slugs);
      return slugs.toSet();
    } catch (_) {
      return _cached();
    }
  }

  static Set<String>? _cached() {
    final cached = CacheManager.getEnabledPackages();
    return cached?.toSet();
  }
}
