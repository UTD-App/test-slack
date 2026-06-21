import 'package:flutter/foundation.dart';

import '../../cache/cache_manager.dart';

/// Incremented to rebuild the entire app (drops navigation + in-memory state).
/// The root [AddonPlatformApp] is keyed by this; bumping it after clearing the
/// session bounces the user back into the auth/login flow.
final ValueNotifier<int> appRestartNotifier = ValueNotifier<int>(0);

/// Rebuild the app from the root.
void restartApp() => appRestartNotifier.value++;

/// Clear the session and bounce to login. Safe to call from anywhere — FCM
/// handlers (a server 'banned' push) or API interceptors (a ban 403). Idempotent.
Future<void> forceLogout() async {
  await CacheManager.clear();
  restartApp();
}
