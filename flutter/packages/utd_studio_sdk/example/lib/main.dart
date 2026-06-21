import 'package:flutter/material.dart';
import 'package:utd_studio_sdk/utd_studio_sdk.dart';

/// Minimal example: wire UTD Studio with STUB adapters (in-memory, no backend).
/// This file MUST NOT import any host app — it shows the SDK is self-contained.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await UtdStudio.init(StudioConfig(
    transport: _StubTransport(),
    cache: _InMemoryCache(),
    // navigator / theme / locale / toast / session are optional — omitted here.
  ));

  // Register a data source your screens bind to (e.g. `core.currentUser`):
  UtdStudio.registerObject(
    'core.currentUser',
    () async => {'name': 'Demo User', 'email': 'demo@example.com'},
  );

  runApp(const _ExampleApp());
}

class _ExampleApp extends StatelessWidget {
  const _ExampleApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: StacDynamicScreen(screenName: 'home'),
    );
  }
}

// --- Stub adapters ---------------------------------------------------------

class _StubTransport implements StacTransport {
  @override
  String get origin => 'https://example.test';

  @override
  Future<dynamic> getJson(String path, {Map<String, dynamic>? query}) async {
    // Pretend the backend has no screens yet.
    return {'data': path == '/stac' ? <dynamic>[] : null};
  }

  @override
  Future<dynamic> postForm(
    String path, {
    Map<String, String> fields = const {},
    String? filePath,
    String? fileField,
    String? fileName,
  }) async =>
      {'data': null};
}

class _InMemoryCache implements KeyValueCache {
  final Map<String, String> _store = {};
  Map<String, dynamic> _user = {};
  Map<String, dynamic> _appConfig = {};

  String _k(String ns, String key) => '$ns/$key';

  @override
  String? getString(String namespace, String key) => _store[_k(namespace, key)];

  @override
  Future<void> putString(String namespace, String key, String value) async =>
      _store[_k(namespace, key)] = value;

  @override
  Future<void> deleteKey(String namespace, String key) async =>
      _store.remove(_k(namespace, key));

  @override
  bool containsKey(String namespace, String key) =>
      _store.containsKey(_k(namespace, key));

  @override
  Map<String, dynamic>? getUserData() => _user;

  @override
  Future<void> saveUserData(Map<String, dynamic> json) async => _user = json;

  @override
  Map<String, dynamic>? getAppConfig() => _appConfig;

  @override
  Future<void> saveAppConfig(Map<String, dynamic> json) async =>
      _appConfig = json;
}
