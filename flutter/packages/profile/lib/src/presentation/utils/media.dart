import 'package:utd_app/config/app_config.dart';

/// Resolve a backend media path (avatar, cover, country flag, frame…) to a
/// displayable URL.
///
/// This mirrors how the rest of the app (reels/social/…) resolves media, so the
/// profile page renders images the *same* way they already show everywhere else:
///   • Full URLs (`http…`) pass through untouched — e.g. externally-hosted
///     avatars like `https://i.pravatar.cc/…`.
///   • Relative storage paths (`avatars/x.jpg`) are served from the app domain
///     (`${appConfig.domainUrl}/storage/…`) — the single source of truth for the
///     host, instead of trusting whatever host the backend happened to build.
/// Returns `''` for null/empty so callers can fall back to a placeholder.
String resolveMediaUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  final clean = path.startsWith('/') ? path.substring(1) : path;
  return '${appConfig.domainUrl}/storage/$clean';
}

/// Avatar URL with a generated fallback when the user has no picture, so an
/// avatar is *never* blank/broken. Matches the reels/social convention.
String avatarUrl(String? image, String? name) {
  final resolved = resolveMediaUrl(image);
  if (resolved.isNotEmpty) return resolved;
  final n = Uri.encodeComponent(
    (name == null || name.trim().isEmpty) ? 'User' : name.trim(),
  );
  return 'https://ui-avatars.com/api/?name=$n&background=4f46e5&color=fff';
}
