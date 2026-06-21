import 'dart:convert';

import '../interfaces/interfaces.dart';

/// Default [StacScreenSource]: fetches server-driven screen JSON and caches it,
/// re-fetching only when the version changes. Renamed from the Base's old
/// `StacService` (which clashed with upstream `stac`'s `StacService`).
///
/// Transport (HTTP) and storage (key/value cache) are injected, so the SDK
/// stays free of any specific HTTP client or storage engine. Screen JSON lives
/// under the `'stac_screens'` cache namespace, keyed `d_<name>` (content) and
/// `v_<name>` (version).
///
/// The host must ensure [cache] is ready (synchronous reads must work) before
/// `UtdStudio.init` — e.g. open the backing box during app bootstrap.
class StacScreenStore implements StacScreenSource {
  StacScreenStore({required this.transport, required this.cache});

  final StacTransport transport;
  final KeyValueCache cache;

  static const String _ns = 'stac_screens';
  static const String _versionPrefix = 'v_';
  static const String _dataPrefix = 'd_';

  @override
  Future<void> init() async {
    // The injected cache is owned and initialized by the host. Kept for
    // interface symmetry and any future warm-up.
  }

  /// Sync all screens — checks versions and fetches only the changed ones.
  @override
  Future<void> syncAll() async {
    try {
      final body = await transport.getJson('/stac');
      final screens =
          (body is Map ? body['data'] : null) as List<dynamic>? ?? const [];
      await Future.wait(
        screens.map(
          (s) => _syncScreen(
            (s as Map)['name'] as String,
            s['version'] as String,
          ),
        ),
      );
    } catch (_) {
      // Network error — use cached screens.
    }
  }

  @override
  Future<Map<String, dynamic>?> getScreen(String name) async {
    try {
      await _syncSingleIfNeeded(name);
    } catch (_) {}
    return _read(name);
  }

  @override
  Map<String, dynamic>? getScreenCached(String name) => _read(name);

  @override
  bool hasScreen(String name) => cache.containsKey(_ns, '$_dataPrefix$name');

  @override
  Future<void> invalidate(String name) async {
    await cache.deleteKey(_ns, '$_versionPrefix$name');
    await _syncSingleIfNeeded(name);
  }

  Map<String, dynamic>? _read(String name) {
    final raw = cache.getString(_ns, '$_dataPrefix$name');
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> _syncScreen(String name, String serverVersion) async {
    final localVersion = cache.getString(_ns, '$_versionPrefix$name');
    if (localVersion == serverVersion) return;
    await _fetchAndStore(name);
  }

  Future<void> _syncSingleIfNeeded(String name) async {
    try {
      final body = await transport.getJson('/stac/$name/version');
      final data = body is Map ? body['data'] : null;
      final serverVersion = data is Map ? data['version'] as String? : null;
      final localVersion = cache.getString(_ns, '$_versionPrefix$name');
      if (serverVersion != null && serverVersion != localVersion) {
        await _fetchAndStore(name);
      }
    } catch (_) {}
  }

  Future<void> _fetchAndStore(String name) async {
    try {
      final body = await transport.getJson('/stac/$name');
      final data = (body is Map ? body['data'] : null) as Map<String, dynamic>?;
      if (data == null) return;
      await cache.putString(
          _ns, '$_dataPrefix$name', jsonEncode(data['content']));
      await cache.putString(_ns, '$_versionPrefix$name', data['version'] as String);
    } catch (_) {}
  }
}
