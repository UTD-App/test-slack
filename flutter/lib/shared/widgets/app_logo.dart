import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../services/launch_gate_service.dart';

/// Renders the admin-managed app logo (Admin → App Settings → App Logo) when one
/// is configured, falling back to [fallback] (typically the bundled asset logo)
/// while it loads, on any network error, or when no admin logo is set.
///
/// The backend returns the logo as a raw storage path (e.g. `settings/x.png`);
/// this resolves it to an absolute URL on the current backend host, so a logo
/// set in the dashboard appears live in the app without a new build.
class AppLogo extends StatelessWidget {
  final Widget fallback;
  final double? width;
  final double? height;
  final BoxFit fit;

  const AppLogo({
    super.key,
    required this.fallback,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  /// Resolve a stored logo value to a loadable URL. Absolute URLs pass through;
  /// a bare storage path is prefixed with the backend host + `/storage/`.
  static String? resolveUrl(String? path) {
    if (path == null) return null;
    final p = path.trim();
    if (p.isEmpty) return null;
    if (p.startsWith('http://') || p.startsWith('https://')) return p;
    final domain = appConfig.domainUrl.replaceAll(RegExp(r'/+$'), '');
    final clean = p.replaceAll(RegExp(r'^/+'), '');
    final tail = clean.startsWith('storage/') ? clean : 'storage/$clean';
    return '$domain/$tail';
  }

  @override
  Widget build(BuildContext context) {
    final url = resolveUrl(AppInfoProvider.current.logo);
    if (url == null) return fallback;

    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      // Any failure (404, offline, bad host) silently shows the bundled logo.
      errorBuilder: (_, __, ___) => fallback,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : fallback,
    );
  }
}
