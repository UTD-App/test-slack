import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../shared/services/app_session.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // When the app is backgrounded/terminated, FCM itself renders the system
  // notification — showing one here too would duplicate it. Nothing to do.
  debugPrint('Background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  /// Fired on every FOREGROUND push so the UI (e.g. the bell badge) can react
  /// live. Set by the notifications feature; base stays decoupled from it.
  static void Function(RemoteMessage message)? onForegroundMessage;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;
  bool _localReady = false;

  /// High-importance channel so a foreground push shows as a heads-up banner
  /// (slides down from the top with a preview) — like an ordinary notification.
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'utd_default',
    'Notifications',
    description: 'App notifications',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final settings = await _messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('Notification permission denied');
      return;
    }

    await _initLocalNotifications();

    final token = await _messaging.getToken();
    debugPrint('FCM Token: $token');

    _foregroundSub = FirebaseMessaging.onMessage.listen(_handleForeground);
    _openedSub = FirebaseMessaging.onMessageOpenedApp.listen(_handleOpened);

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _handleOpened(initial);
    }
  }

  /// Sets up flutter_local_notifications and registers the heads-up channel so
  /// we can display pushes while the app is in the foreground.
  Future<void> _initLocalNotifications() async {
    if (_localReady) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    _localReady = true;
  }

  Future<String?> getToken() => _messaging.getToken();

  void _handleForeground(RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');
    _showHeadsUp(message);
    onForegroundMessage?.call(message);
    _maybeHandleBan(message);
  }

  /// Renders an in-app heads-up notification for a foreground push. FCM does NOT
  /// auto-display notifications while the app is open, so we do it ourselves —
  /// it then looks and behaves like any normal system notification.
  void _showHeadsUp(RemoteMessage message) {
    if (!_localReady) return;

    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] as String?;
    final body = notification?.body ?? message.data['body'] as String?;
    if (title == null && body == null) return;

    _local.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          // Preview a chunk of the body even when it's long.
          styleInformation: body != null
              ? BigTextStyleInformation(body)
              : null,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data['route'] as String?,
    );
  }

  void _handleOpened(RemoteMessage message) {
    debugPrint('Notification opened: ${message.data}');
    _maybeHandleBan(message);
  }

  /// A server 'banned' data push force-logs-out the user in real time.
  void _maybeHandleBan(RemoteMessage message) {
    if (message.data['type'] == 'banned') {
      forceLogout();
    }
  }

  Future<void> dispose() async {
    await _foregroundSub?.cancel();
    await _openedSub?.cancel();
  }
}
