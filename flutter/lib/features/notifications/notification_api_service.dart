import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/network/services/base_api_service.dart';

import 'notification_models.dart';

/// Talks to the Base notification API (paths are relative to the configured
/// API base, which already includes the prefix — same convention as the
/// social/profile packages).
class NotificationApiService extends BaseApiService {
  Future<Result<List<NotificationItem>>> fetchFeed({int page = 1}) {
    return get<List<NotificationItem>>(
      '/notifications',
      queryParameters: {'page': page},
      fromJson: (json) {
        final items = (json['data']?['items'] as List?) ?? const [];
        return items
            .map((e) => NotificationItem.fromJson((e as Map).cast<String, dynamic>()))
            .toList();
      },
    );
  }

  Future<Result<int>> unreadCount() {
    return get<int>(
      '/notifications/unread-count',
      fromJson: (json) => (json['data']?['unread_count'] as num?)?.toInt() ?? 0,
    );
  }

  Future<Result<bool>> markRead(int id) {
    return post<bool>('/notifications/$id/read', fromJson: (_) => true);
  }

  Future<Result<bool>> markAllRead() {
    return post<bool>('/notifications/read-all', fromJson: (_) => true);
  }

  /// Registers the FCM device token (and the user's locale, via X-localization)
  /// so push can target this device. Best-effort.
  Future<Result<bool>> registerDeviceToken(String token) {
    return post<bool>(
      '/notifications/device-token',
      data: {'device_token': token},
      fromJson: (_) => true,
    );
  }
}
