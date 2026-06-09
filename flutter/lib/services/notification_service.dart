import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final settings = await _messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('Notification permission denied');
      return;
    }

    final token = await _messaging.getToken();
    debugPrint('FCM Token: $token');

    _foregroundSub = FirebaseMessaging.onMessage.listen(_handleForeground);
    _openedSub = FirebaseMessaging.onMessageOpenedApp.listen(_handleOpened);

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _handleOpened(initial);
    }
  }

  Future<String?> getToken() => _messaging.getToken();

  void _handleForeground(RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');
  }

  void _handleOpened(RemoteMessage message) {
    debugPrint('Notification opened: ${message.data}');
  }

  Future<void> dispose() async {
    await _foregroundSub?.cancel();
    await _openedSub?.cancel();
  }
}
