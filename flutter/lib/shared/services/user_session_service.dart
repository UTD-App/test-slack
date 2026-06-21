import 'package:utd_app/cache/cache_manager.dart';
import 'package:utd_app/network/client/api_client.dart';
import 'package:utd_app/services/firebase_service.dart';
import 'package:utd_app/services/notification_service.dart';
import 'package:utd_app/shared/models/my_data_model.dart';
import 'package:utd_app/shared/notifiers/user_data_notifier.dart';

/// Loads the signed-in user from the backend (`GET /my-data`) into
/// [UserDataNotifier] and the local cache.
///
/// The login/register responses only carry `id` / `is_first` / `auth_token`
/// (no user object), so without this the app never knows the current user's
/// id — and screens like the profile page request `/users/0/profile` →
/// "User not found". Call this after login, after registration, and on app
/// start while a session exists.
class UserSessionService {
  UserSessionService._();

  static Future<void> hydrate(UserDataNotifier notifier) async {
    try {
      final response = await ApiClient.instance.dio.get('/my-data');
      final data = response.data is Map ? response.data['data'] : null;
      if (data is Map<String, dynamic>) {
        final user = MyDataModel.fromJson(data);
        notifier.setUser(user);
        await CacheManager.saveUserData(user.toJson());
        await _registerDeviceToken();
        return;
      }
    } catch (_) {
      // Offline / transient failure — fall through to the cached copy below.
    }

    // Fallback: whatever was cached from a previous session (keeps the user id
    // available when /my-data can't be reached).
    final cached = CacheManager.getUserData();
    if (cached != null) {
      notifier.setUser(MyDataModel.fromJson(cached));
    }
  }

  /// Registers this device's FCM token with the backend so push can target it.
  /// Best-effort: no-op when Firebase isn't initialized (e.g. no
  /// google-services.json) or the token/request fails.
  static Future<void> _registerDeviceToken() async {
    if (!FirebaseService.isInitialized) return;
    try {
      final token = await NotificationService().getToken();
      if (token == null || token.isEmpty) return;
      await ApiClient.instance.dio.post(
        '/notifications/device-token',
        data: {'device_token': token},
      );
    } catch (_) {
      // best-effort
    }
  }
}
