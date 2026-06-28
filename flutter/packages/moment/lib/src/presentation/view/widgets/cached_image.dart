import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:utd_app/shared/media/app_cache_manager.dart';

/// Network image for the moments UI, served through the app's shared on-disk
/// media cache ([AppCacheManager]) so each image downloads once, survives
/// scroll/refresh, and shows offline. A soft fill stands in while it loads and
/// a broken-image glyph on failure.
class MomentNetworkImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;

  const MomentNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _error();
    return CachedNetworkImage(
      imageUrl: url,
      cacheManager: AppCacheManager.instance.manager,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (_, __) => _placeholder(),
      errorWidget: (_, __, ___) => _error(),
    );
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
