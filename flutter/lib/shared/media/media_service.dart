import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:utd_app/localization/localization.dart';
import 'package:utd_app/localization/localization_extensions.dart';
import 'package:utd_app/network/client/api_client.dart';
import 'package:utd_app/shared/core/toast_manager.dart';
import 'package:utd_app/shared/services/permission_service.dart';

/// Outcome of a successful upload.
class MediaUploadResult {
  /// Canonical storage path — send THIS to feature endpoints (e.g. profile).
  final String path;

  /// Public URL — use for immediate display.
  final String url;

  const MediaUploadResult({required this.path, required this.url});
}

/// Reusable image pick + upload helper shared across the whole app.
///
/// Uploads go through the backend's provider-agnostic `/media/upload`, so
/// switching storage to S3 / Google Cloud later is an admin-settings change
/// with NO client change. Typical use from any feature:
///
/// ```dart
/// final file = await MediaService.instance.pickImage(context);
/// if (file == null) return;
/// final result = await MediaService.instance.uploadImage(file, folder: 'avatars');
/// // send result.path to your endpoint; show result.url
/// ```
class MediaService {
  MediaService._();
  static final MediaService instance = MediaService._();

  final ImagePicker _picker = ImagePicker();

  /// Shows a gallery/camera sheet and returns the picked image (or null if the
  /// user dismissed it). Images are downscaled to keep uploads light, then
  /// compressed unless [compress] is false.
  Future<XFile?> pickImage(
    BuildContext context, {
    bool allowCamera = true,
    bool compress = true,
  }) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(sheetContext.tr('app.gallery')),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            if (allowCamera)
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(sheetContext.tr('app.camera')),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
          ],
        ),
      ),
    );
    if (source == null) return null;

    // Camera needs an explicit runtime permission; the gallery goes through the
    // OS photo picker which manages its own access. Ask the base, never talk to
    // permission_handler from a feature.
    if (source == ImageSource.camera) {
      final granted = await PermissionService.instance.requestCamera();
      if (!granted) {
        if (context.mounted) {
          ToastManager.showToast(
            context,
            message: context.tr('app.permission_denied'),
            isError: true,
          );
        }
        return null;
      }
    }

    final picked =
        await _picker.pickImage(source: source, maxWidth: 1024, imageQuality: 85);
    if (picked == null) return null;

    return compress ? await _compress(picked) : picked;
  }

  /// Compresses [file] into a lighter JPEG before upload. image_picker already
  /// downscales, but this trims large camera shots further and normalizes the
  /// format. Returns the original on web or if compression fails.
  Future<XFile> _compress(XFile file) async {
    if (kIsWeb) return file;
    try {
      final dir = await getTemporaryDirectory();
      final target =
          '${dir.path}/utd_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final result = await FlutterImageCompress.compressAndGetFile(
        file.path,
        target,
        quality: 70,
        minWidth: 1080,
        minHeight: 1080,
        format: CompressFormat.jpeg,
      );
      return result ?? file;
    } catch (e) {
      debugPrint('MediaService._compress failed: $e');
      return file;
    }
  }

  /// Uploads [file] to the reusable `/media/upload` endpoint under [folder].
  /// Returns the stored path + public URL, or null on a malformed response.
  Future<MediaUploadResult?> uploadImage(XFile file, {String folder = 'uploads'}) async {
    final form = FormData.fromMap({
      'folder': folder,
      'file': await MultipartFile.fromFile(file.path, filename: file.name),
    });

    final response = await ApiClient.instance.dio.post('/media/upload', data: form);

    final data = response.data;
    if (data is Map && data['data'] is Map) {
      final d = data['data'] as Map;
      final path = d['path']?.toString();
      final url = d['url']?.toString();
      if (path != null && url != null) {
        return MediaUploadResult(path: path, url: url);
      }
    }
    return null;
  }
}
