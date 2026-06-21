import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../addons/app_feature.dart';
import '../../addons/ui_contribution.dart';
import '../../addons/user_data_extension.dart';
import '../../services/notification_service.dart';
import 'notification_data_extension.dart';
import 'notification_strings.dart';
import 'notifications_page.dart';

/// Built-in Notifications feature: an in-app feed (bottom-nav tab) with a live
/// unread badge, backed by the Base notification system. Core — always on.
class NotificationsFeature extends AppFeature {
  // Single shared instance so the my-data distribution (getUserDataExtensions)
  // and the widget tree provider (getProviders) update the SAME object → the
  // badge reacts to both /my-data and in-app read actions.
  final NotificationDataExtension _data = NotificationDataExtension();

  NotificationsFeature() {
    // Bump the bell badge the moment a push lands while the app is foregrounded
    // (the heads-up banner itself is shown by NotificationService).
    NotificationService.onForegroundMessage = (_) => _data.increment();
  }

  @override
  String get id => 'com.utd.notifications';

  @override
  String get displayName => 'Notifications';

  @override
  bool get isCore => true;

  @override
  List<GoRoute> getRoutes() => [
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsPage(),
        ),
      ];

  // Notifications no longer occupy a bottom-nav tab — the bell now lives in the
  // home top bar (see HomeScreen). The /notifications route, provider, and live
  // unread badge are kept so the top-bar bell stays fully functional.
  @override
  List<UiContribution> getUiContributions() => const [];

  @override
  List<SingleChildWidget> getProviders() => [
        ChangeNotifierProvider<NotificationDataExtension>.value(value: _data),
      ];

  @override
  List<UserDataExtension> getUserDataExtensions() => [_data];

  @override
  Map<String, Map<String, String>> getTranslations() => notificationTranslations;
}
