import 'package:utd_app/config/app_config.dart';

/// Resolve a backend media path (gift image, supporter avatar…) to a displayable
/// URL — the same convention the rest of the app uses, so images load on every
/// device (not just the emulator). Full URLs pass through; relative storage paths
/// are served from the app domain. Returns `''` for null/empty.
String resolveMediaUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  final clean = path.startsWith('/') ? path.substring(1) : path;
  return '${appConfig.domainUrl}/storage/$clean';
}
