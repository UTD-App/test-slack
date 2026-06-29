import 'package:flutter_test/flutter_test.dart';
import 'package:utd_app/shared/media/media_service.dart';

/// Tests for media_service.dart.
///
/// SCOPE / LIMITATION:
///   `MediaService` (the singleton) is an image *upload* helper whose every
///   method is non-deterministic without network/IO/platform plugins:
///     - pickImage      -> showModalBottomSheet + ImagePicker + PermissionService
///     - _compress      -> getTemporaryDirectory + FlutterImageCompress (native)
///     - uploadImage    -> ApiClient.instance.dio.post('/media/upload') (network)
///   None of these can be exercised deterministically here without mocks (banned
///   by the task constraints) or a live backend, so they are intentionally NOT
///   tested in this file.
///
///   The only pure, deterministic surface is the `MediaUploadResult` value
///   object, covered below.
///
///   NOTE on "media URL resolution": the memory-flagged raw-path-vs-absolute-URL
///   resolver is `AppConfig.storageUrl(path)` (used by NetworkImageWidget via
///   `appConfig.storageUrl`), which is already covered by
///   test/config/app_config_test.dart — not duplicated here.
void main() {
  group('MediaUploadResult', () {
    test('stores the path and url it is constructed with', () {
      const result = MediaUploadResult(
        path: 'avatars/u42.jpg',
        url: 'https://storage.googleapis.com/base-app-utd/avatars/u42.jpg',
      );
      expect(result.path, 'avatars/u42.jpg');
      expect(result.url,
          'https://storage.googleapis.com/base-app-utd/avatars/u42.jpg');
    });

    test('path and url are independent fields (canonical path vs display url)', () {
      // The doc contract: send `path` to feature endpoints, show `url`.
      const result = MediaUploadResult(path: 'p', url: 'u');
      expect(result.path, isNot(equals(result.url)));
      expect(result.path, 'p');
      expect(result.url, 'u');
    });

    test('is a const-constructible value object', () {
      const a = MediaUploadResult(path: 'p', url: 'u');
      const b = MediaUploadResult(path: 'p', url: 'u');
      // Identical const args canonicalise to the same instance.
      expect(identical(a, b), isTrue);
    });

    test('accepts empty strings (no validation in the value object)', () {
      const result = MediaUploadResult(path: '', url: '');
      expect(result.path, '');
      expect(result.url, '');
    });
  });

  group('MediaService singleton', () {
    test('exposes a single shared instance', () {
      expect(MediaService.instance, same(MediaService.instance));
    });
  });
}
