import 'package:flutter/widgets.dart';

/// The injectable ports UTD Studio needs from the host app. Implemented once,
/// in the app, and passed into [UtdStudio.init] via `StudioConfig`. The SDK
/// never imports app code — it only talks to these contracts.

/// Screen + data JSON transport. Implemented in the app over its HTTP client
/// (e.g. `ApiClient.instance.dio`). Only the endpoints the SDUI actually hits
/// are exposed.
abstract class StacTransport {
  /// GET returning the decoded JSON body. Used for `/stac`, `/stac/{name}`,
  /// `/stac/{name}/version`, `/my-data`, `/configs`.
  Future<dynamic> getJson(String path, {Map<String, dynamic>? query});

  /// POST a multipart form (optional single file). Used for `/profile/update`,
  /// `/profile/avatar`. The SDK never imports `dio` — files travel as a path.
  Future<dynamic> postForm(
    String path, {
    Map<String, String> fields = const {},
    String? filePath,
    String? fileField,
    String? fileName,
  });

  /// API origin (baseUrl minus trailing `/` and `/api`); used to absolutise
  /// relative asset URLs (e.g. the logo) in `core.app` branding.
  String get origin;
}

/// Namespaced key/value store. Implemented over Hive/`CacheManager` in the app.
/// Server-driven screen JSON is stored under the `'stac_screens'` namespace as
/// String (preserving `v_`/`d_` prefixes). The SDK stays storage-agnostic and
/// does NOT depend on any storage engine.
abstract class KeyValueCache {
  String? getString(String namespace, String key);
  Future<void> putString(String namespace, String key, String value);
  Future<void> deleteKey(String namespace, String key);
  bool containsKey(String namespace, String key);

  /// Convenience JSON blobs used by the default data sources / glue.
  Map<String, dynamic>? getUserData();
  Future<void> saveUserData(Map<String, dynamic> json);
  Map<String, dynamic>? getAppConfig();
  Future<void> saveAppConfig(Map<String, dynamic> json);
}

/// The server-driven screen store contract. The default implementation
/// ([StacScreenStore]) ships in the package; `StacDynamicScreen` AND
/// `core.openDialog` read the SAME resolved instance from `StudioRuntime`.
abstract class StacScreenSource {
  Future<void> init();
  Future<void> syncAll();

  /// Network-aware fetch (syncs if a newer version exists), then returns JSON.
  Future<Map<String, dynamic>?> getScreen(String name);

  /// Synchronous, cache-only read (no network) — for no-spinner-flash startup.
  Map<String, dynamic>? getScreenCached(String name);

  bool hasScreen(String name);
  Future<void> invalidate(String name);
}

/// Route-string navigation, implemented over the app's router (e.g. `go_router`).
/// The generic `core.navigate` / `core.back` actions pass the `BuildContext`
/// they receive in `onCall`, so the adapter can use context-based routing
/// (e.g. go_router's `context.go`) exactly as before.
abstract class AppNavigator {
  void push(BuildContext context, String route, {Object? extra});
  void replace(BuildContext context, String route, {Object? extra});
  void go(BuildContext context, String route, {Object? extra});
  bool canPop(BuildContext context);
  void pop(BuildContext context);

  /// `core.back` fallback when nothing can be popped (e.g. the app's home route).
  String get home;
}

/// Theme switching. Over the app's theme notifier.
/// [modeName] is `'light' | 'dark' | 'system'`; `null` means toggle.
abstract class ThemeSource {
  Future<void> setMode(String? modeName);
  Future<void> toggle();
}

/// Locale switching. Over the app's locale notifier. Should swallow unsupported
/// language codes rather than throw.
abstract class LocaleSource {
  Future<void> setLanguage(String code);
}

/// User-facing toast. Over the app's toast utility. Keeps a [BuildContext]
/// because overlay-based toasts require one.
abstract class ToastSink {
  void show(BuildContext context, {required String message, bool isError = false});
}

/// The signed-in user as plain JSON (never a typed app model). Over the app's
/// user notifier. Keeps the SDK free of app domain types.
abstract class UserSession {
  Map<String, dynamic>? getUser();
  void setUser(Map<String, dynamic> json);

  /// Merge primitive fields (e.g. name/email/bio/avatar) into the current user.
  void update(Map<String, dynamic> fields);
  void clear();
}
