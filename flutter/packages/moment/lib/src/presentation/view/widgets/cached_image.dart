import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:utd_app/shared/media/app_cache_manager.dart';

/// Network image for the moments UI, served through the app's shared on-disk
/// media cache ([AppCacheManager]) so each image downloads once, survives
/// scroll/refresh, and shows offline. A soft fill stands in while it loads and
/// a broken-image glyph on failure.
///
/// The bitmap is decoded at the actual display width (`memCacheWidth`) so a
/// thumbnail doesn't hold a full-resolution image in memory — the full file
/// stays on disk (the gallery still shows it sharp), only the in-memory copy is
/// right-sized. An optional [semanticLabel] exposes the image to screen readers.
class MomentNetworkImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String? semanticLabel;

  const MomentNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _semantics(_error());
    final dpr = MediaQuery.of(context).devicePixelRatio;
    return _semantics(
      LayoutBuilder(
        builder: (context, constraints) {
          // Decode at the rendered width × pixel ratio (skip when unbounded).
          final w = constraints.maxWidth;
          final memWidth = w.isFinite ? (w * dpr).round() : null;
          return CachedNetworkImage(
            imageUrl: url,
            cacheManager: AppCacheManager.instance.manager,
            width: width,
            height: height,
            fit: fit,
            memCacheWidth: memWidth,
            fadeInDuration: const Duration(milliseconds: 200),
            placeholder: (_, __) => _placeholder(),
            errorWidget: (_, __, ___) => _error(),
          );
        },
      ),
    );
  }

  Widget _semantics(Widget child) {
    if (semanticLabel == null || semanticLabel!.isEmpty) return child;
    return Semantics(image: true, label: semanticLabel, child: child);
  }

  Widget _placeholder() => Container(
        width: width,
        height: height,
        color: Colors.grey.withValues(alpha: 0.12),
      );

  Widget _error() => Container(
        width: width,
        height: height,
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image, color: Colors.grey),
      );
}
