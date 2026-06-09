import 'package:flutter/foundation.dart';

/// Contract for packages that contribute user-scoped data.
///
/// Each extension owns a namespaced [key] that matches a top-level key
/// in the API response from `/me` or login. The [FeatureRegistry] distributes
/// incoming user data to each registered extension by key.
///
/// Example:
/// ```dart
/// class SocialDataExtension extends UserDataExtension {
///   @override
///   String get key => 'social';
///
///   int fans = 0;
///   int followings = 0;
///
///   @override
///   void onDataReceived(Map<String, dynamic>? data) {
///     fans = data?['fans'] as int? ?? 0;
///     followings = data?['followings'] as int? ?? 0;
///     notifyListeners();
///   }
///
///   @override
///   Map<String, dynamic>? serializeData() => {
///     'fans': fans,
///     'followings': followings,
///   };
///
///   @override
///   void onDataCleared() {
///     fans = 0;
///     followings = 0;
///     notifyListeners();
///   }
/// }
/// ```
abstract class UserDataExtension extends ChangeNotifier {
  /// Namespaced key matching the API response section.
  /// E.g., `'social'`, `'privacy'`, `'messaging'`.
  String get key;

  /// Called when user data arrives (login, `/me`, or cache restore).
  /// [data] is the value at `response[key]`, or `null` if absent.
  void onDataReceived(Map<String, dynamic>? data);

  /// Returns current data as a serialisable map for caching.
  /// Return `null` if nothing to persist.
  Map<String, dynamic>? serializeData();

  /// Called on logout — reset to defaults.
  void onDataCleared();
}
