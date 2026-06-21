import 'package:permission_handler/permission_handler.dart';

/// Centralized runtime-permission gateway shared across the whole app.
///
/// Follows the base golden rule: packages ASK, the base EXECUTES. A feature
/// (profile avatar, chat voice note, nearby users…) never talks to
/// `permission_handler` directly — it calls a method here and gets back a
/// simple `bool granted`. The base owns the request flow, including the
/// "permanently denied → open app settings" fallback.
///
/// Typical use from any feature:
/// ```dart
/// if (await PermissionService.instance.requestCamera()) {
///   // open the camera
/// }
/// ```
///
/// The underlying permissions must also be declared per-platform
/// (AndroidManifest.xml `<uses-permission>` / iOS Info.plist usage strings),
/// otherwise the request resolves to denied/restricted immediately.
class PermissionService {
  PermissionService._();
  static final PermissionService instance = PermissionService._();

  /// Camera access (taking photos / recording video).
  Future<bool> requestCamera() => _ensure(Permission.camera);

  /// Photo library / gallery access. On Android 13+ this maps to
  /// `READ_MEDIA_IMAGES`; on older versions to storage.
  Future<bool> requestPhotos() => _ensure(Permission.photos);

  /// Microphone access (voice notes, calls, recording).
  Future<bool> requestMicrophone() => _ensure(Permission.microphone);

  /// Foreground (while-in-use) location access.
  Future<bool> requestLocationWhenInUse() => _ensure(Permission.locationWhenInUse);

  /// Push/local notification permission (Android 13+ POST_NOTIFICATIONS, iOS).
  Future<bool> requestNotifications() => _ensure(Permission.notification);

  /// Whether [permission] is currently granted, without prompting.
  Future<bool> isGranted(Permission permission) => permission.isGranted;

  /// Requests [permission] and returns whether it ended up granted.
  ///
  /// Flow:
  /// - already granted (or limited, e.g. iOS partial photo access) → true
  /// - permanently denied / restricted → opens the OS app settings so the
  ///   user can flip it manually, returns false for this call
  /// - otherwise → prompts, returns the resulting grant state
  Future<bool> _ensure(Permission permission) async {
    final status = await permission.status;

    if (status.isGranted || status.isLimited) return true;

    if (status.isPermanentlyDenied || status.isRestricted) {
      await openAppSettings();
      return false;
    }

    final result = await permission.request();
    return result.isGranted || result.isLimited;
  }
}
