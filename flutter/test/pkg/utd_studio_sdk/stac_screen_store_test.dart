import 'package:flutter_test/flutter_test.dart';
import 'package:utd_studio_sdk/utd_studio_sdk.dart';

/// In-memory [KeyValueCache] — only the namespaced string API is exercised by
/// [StacScreenStore]; the convenience blobs are unused here.
class _FakeCache implements KeyValueCache {
  final Map<String, String> _store = {};
  String _k(String ns, String key) => '$ns::$key';

  @override
  String? getString(String ns, String key) => _store[_k(ns, key)];
  @override
  Future<void> putString(String ns, String key, String value) async =>
      _store[_k(ns, key)] = value;
  @override
  Future<void> deleteKey(String ns, String key) async =>
      _store.remove(_k(ns, key));
  @override
  bool containsKey(String ns, String key) => _store.containsKey(_k(ns, key));

  @override
  Map<String, dynamic>? getUserData() => null;
  @override
  Future<void> saveUserData(Map<String, dynamic> json) async {}
  @override
  Map<String, dynamic>? getAppConfig() => null;
  @override
  Future<void> saveAppConfig(Map<String, dynamic> json) async {}
}

/// Scripted [StacTransport] — returns canned JSON per path, records GET calls,
/// and can be told to throw (offline) for a path.
class _FakeTransport implements StacTransport {
  _FakeTransport(this.responses);
  final Map<String, dynamic> responses;
  final List<String> calls = [];
  final Set<String> failPaths = {};

  @override
  Future<dynamic> getJson(String path, {Map<String, dynamic>? query}) async {
    calls.add(path);
    if (failPaths.contains(path)) throw Exception('offline: $path');
    return responses[path];
  }

  @override
  Future<dynamic> postForm(String path,
          {Map<String, String> fields = const {},
          String? filePath,
          String? fileField,
          String? fileName}) async =>
      null;

  @override
  String get origin => 'https://example.test';
}

void main() {
  late _FakeCache cache;

  setUp(() => cache = _FakeCache());

  Map<String, dynamic> screenBody(String text) => {
        'type': 'text',
        'data': text,
      };

  group('getScreen', () {
    test('fetches + caches on first call, then reads cache (no re-fetch)',
        () async {
      final transport = _FakeTransport({
        '/stac/login/version': {
          'data': {'version': 'v1'},
        },
        '/stac/login': {
          'data': {'version': 'v1', 'content': screenBody('Login')},
        },
      });
      final store = StacScreenStore(transport: transport, cache: cache);

      final first = await store.getScreen('login');
      expect(first, screenBody('Login'));
      expect(store.hasScreen('login'), isTrue);

      // Cached read with no version change → only the version probe, no /stac/login.
      transport.calls.clear();
      final cached = store.getScreenCached('login');
      expect(cached, screenBody('Login'));
      expect(transport.calls, isEmpty);
    });

    test('re-fetches when the server version changes', () async {
      final transport = _FakeTransport({
        '/stac/login/version': {
          'data': {'version': 'v1'},
        },
        '/stac/login': {
          'data': {'version': 'v1', 'content': screenBody('Login v1')},
        },
      });
      final store = StacScreenStore(transport: transport, cache: cache);
      expect(await store.getScreen('login'), screenBody('Login v1'));

      // Bump server version + content.
      transport.responses['/stac/login/version'] = {
        'data': {'version': 'v2'},
      };
      transport.responses['/stac/login'] = {
        'data': {'version': 'v2', 'content': screenBody('Login v2')},
      };
      expect(await store.getScreen('login'), screenBody('Login v2'));
    });

    test('version probe failing falls back to the cached screen', () async {
      final transport = _FakeTransport({
        '/stac/login/version': {
          'data': {'version': 'v1'},
        },
        '/stac/login': {
          'data': {'version': 'v1', 'content': screenBody('Login')},
        },
      });
      final store = StacScreenStore(transport: transport, cache: cache);
      await store.getScreen('login'); // warm cache

      transport.failPaths.add('/stac/login/version');
      final out = await store.getScreen('login');
      expect(out, screenBody('Login'), reason: 'served from cache while offline');
    });

    test('unknown, never-cached screen returns null', () async {
      final transport = _FakeTransport({});
      transport.failPaths.add('/stac/ghost/version');
      final store = StacScreenStore(transport: transport, cache: cache);
      expect(await store.getScreen('ghost'), isNull);
      expect(store.hasScreen('ghost'), isFalse);
    });
  });

  group('getScreenCached / hasScreen', () {
    test('cache-only read returns null before any sync', () {
      final store =
          StacScreenStore(transport: _FakeTransport({}), cache: cache);
      expect(store.getScreenCached('login'), isNull);
      expect(store.hasScreen('login'), isFalse);
    });

    test('corrupt cached JSON yields null (not a throw)', () async {
      // Seed the cache with non-JSON content under the data key.
      await cache.putString('stac_screens', 'd_login', '{not valid json');
      final store =
          StacScreenStore(transport: _FakeTransport({}), cache: cache);
      expect(store.getScreenCached('login'), isNull);
      // hasScreen only checks key presence, so it is still true.
      expect(store.hasScreen('login'), isTrue);
    });
  });

  group('syncAll', () {
    test('fetches only the screens whose version changed', () async {
      final transport = _FakeTransport({
        '/stac': {
          'data': [
            {'name': 'a', 'version': 'v1'},
            {'name': 'b', 'version': 'v1'},
          ],
        },
        '/stac/a': {
          'data': {'version': 'v1', 'content': screenBody('A')},
        },
        '/stac/b': {
          'data': {'version': 'v1', 'content': screenBody('B')},
        },
      });
      final store = StacScreenStore(transport: transport, cache: cache);

      await store.syncAll();
      expect(store.getScreenCached('a'), screenBody('A'));
      expect(store.getScreenCached('b'), screenBody('B'));

      // Second syncAll with same versions → no per-screen fetches.
      transport.calls.clear();
      await store.syncAll();
      expect(transport.calls, ['/stac']); // listing only, no /stac/a|/stac/b
    });

    test('network error during syncAll is swallowed', () async {
      final transport = _FakeTransport({});
      transport.failPaths.add('/stac');
      final store = StacScreenStore(transport: transport, cache: cache);
      await store.syncAll(); // should not throw
      expect(store.hasScreen('a'), isFalse);
    });
  });

  group('invalidate', () {
    test('clears the version then re-syncs the screen', () async {
      final transport = _FakeTransport({
        '/stac/login/version': {
          'data': {'version': 'v1'},
        },
        '/stac/login': {
          'data': {'version': 'v1', 'content': screenBody('Login')},
        },
      });
      final store = StacScreenStore(transport: transport, cache: cache);
      await store.getScreen('login');

      // Change content but KEEP version; without invalidate it wouldn't refetch.
      transport.responses['/stac/login'] = {
        'data': {'version': 'v1', 'content': screenBody('Refreshed')},
      };
      await store.invalidate('login');
      expect(store.getScreenCached('login'), screenBody('Refreshed'));
    });
  });
}
