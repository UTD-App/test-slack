import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:utd_app/shared/services/stac_service.dart';

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
  static const Duration _startupTimeout = Duration(seconds: 4);

  /// The active bottom-nav config (null → fall back to the native nav).
  final ValueNotifier<BottomNavConfig?> navConfig = ValueNotifier(null);

  Future<void> applyIfPresent() async {
    Map<String, dynamic>? json;
    try {
      json = await StacService.instance
          .getScreen(documentName)
          .timeout(_startupTimeout);
    } on TimeoutException {
      json = StacService.instance.getScreenCached(documentName);
    } catch (_) {
      json = StacService.instance.getScreenCached(documentName);
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
