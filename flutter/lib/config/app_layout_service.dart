import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:utd_studio_sdk/utd_studio_sdk.dart';

import 'app_flow.dart';
import 'app_layout.dart';

/// Loads the server-delivered `app_layout` document and applies it to the app:
/// overrides [AppFlow] (so the router guard + boot resolver use the customer
/// flow) and exposes the [BottomNavConfig] for the home shell.
///
/// Reuses [StacService] (version-checked Hive cache) so the layout persists
/// across restarts and works offline. Called once from `main()` BEFORE
/// `runApp` so the router is built with the final flow. A network read with a
/// short timeout keeps first-launch-after-publish correct without blocking
/// startup; on timeout it falls back to the cached copy.
class AppLayoutService {
  static final AppLayoutService instance = AppLayoutService._();
  AppLayoutService._();

  static const String documentName = 'app_layout';
  // 9s (not 4s): on a fresh install the cold-cache fetch of app_layout from a
  // cold server often exceeds 4s, so the app fell back to native nav on first
  // launch and only showed the server-driven shell on the 2nd launch.
  static const Duration _startupTimeout = Duration(seconds: 9);

  /// The active bottom-nav config (null → fall back to the native nav).
  final ValueNotifier<BottomNavConfig?> navConfig = ValueNotifier(null);

  Future<void> applyIfPresent() async {
    Map<String, dynamic>? json;
    try {
      json = await StudioRuntime.instance.screenSource
          .getScreen(documentName)
          .timeout(_startupTimeout);
    } on TimeoutException {
      json = StudioRuntime.instance.screenSource.getScreenCached(documentName);
    } catch (_) {
      json = StudioRuntime.instance.screenSource.getScreenCached(documentName);
    }

    final layout = AppLayout.fromJson(json);
    if (layout == null) {
      debugPrint('[UTD] app_layout: none — using AppFlow.fallback + native nav');
      return;
    }

    if (layout.flow != null) AppFlow.override(layout.flow!);
    navConfig.value = layout.bottomNav;
    debugPrint('[UTD] app_layout applied — flow=${layout.flow != null} '
        'tabs=${layout.bottomNav?.tabs.length ?? 0}');
  }
}
