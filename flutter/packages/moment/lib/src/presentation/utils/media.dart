import 'package:utd_app/config/app_config.dart';

/// Resolve a backend media path to a displayable URL.
/// Full URLs pass through; relative storage paths are served from the app domain.
String resolveMediaUrl(String path) {
  if (path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  final clean = path.startsWith('/') ? path.substring(1) : path;
  return '${appConfig.domainUrl}/storage/$clean';
}

/// Avatar URL with a generated fallback when the user has no picture.
String avatarUrl(String image, String name) {
  if (image.startsWith('http')) return image;
  if (image.isNotEmpty) return resolveMediaUrl(image);
  final n = Uri.encodeComponent(name.trim().isEmpty ? 'User' : name.trim());
  return 'https://ui-avatars.com/api/?name=$n&background=4f46e5&color=fff';
}
