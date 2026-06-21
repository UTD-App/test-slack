import 'package:utd_app/addons/user_data_extension.dart';

/// Holds the unread notification count, fed from the `notifications` block of
/// /api/my-data (see Base NotificationDataContributor) and kept live as the user
/// reads notifications. Drives the bell badge. Provided to the tree via the
/// feature's getProviders() so widgets can Consumer/watch it.
class NotificationDataExtension extends UserDataExtension {
  int unreadCount = 0;

  @override
  String get key => 'notifications';

  @override
  void onDataReceived(Map<String, dynamic>? data) {
    unreadCount = (data?['unread_count'] as num?)?.toInt() ?? 0;
    notifyListeners();
  }

  @override
  Map<String, dynamic>? serializeData() => {'unread_count': unreadCount};

  @override
  void onDataCleared() {
    unreadCount = 0;
    notifyListeners();
  }

  /// Set the exact count (e.g. after fetching the feed / unread-count).
  void setUnread(int value) {
    unreadCount = value < 0 ? 0 : value;
    notifyListeners();
  }

  /// Decrement when a single notification is marked read.
  void decrement() {
    if (unreadCount > 0) {
      unreadCount--;
      notifyListeners();
    }
  }

  /// Increment when a new notification lands via push (live badge bump).
  void increment() {
    unreadCount++;
    notifyListeners();
  }
}
