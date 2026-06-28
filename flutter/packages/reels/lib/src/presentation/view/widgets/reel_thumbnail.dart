import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// A still preview for a reel (used by the My-Reels / user-reels grid).
///
/// Prefers the server-generated poster ([posterUrl]); when that is missing or
/// fails to load — the FFmpeg poster pipeline is optional and often absent
/// (no binary, external video URLs) — it extracts a frame from the video itself
/// on-device and caches it. Without this the grid tiles render as black
/// rectangles because no poster file exists.
class ReelThumbnail extends StatelessWidget {
  /// Resolved (absolute) video URL.
  final String videoUrl;

  /// Resolved poster URL; may be empty or point at a missing file.
  final String posterUrl;

  final BoxFit fit;

  const ReelThumbnail({
    super.key,
    required this.videoUrl,
    this.posterUrl = '',
    this.fit = BoxFit.cover,
  });

  // One generation Future per video URL so scroll/rebuilds reuse the result
  // instead of re-decoding the video.
  static final Map<String, Future<Uint8List?>> _cache = {};

  static Future<Uint8List?> _frame(String url) {
    return _cache[url] ??= VideoThumbnail.thumbnailData(
      video: url,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 300,
      quality: 60,
    ).then<Uint8List?>((b) => b).catchError((_) => null);
  }

  @override
  Widget build(BuildContext context) {
    if (posterUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: posterUrl,
        fit: fit,
        // Grid tiles are small — decode at 300px to keep memory/decode low.
        memCacheWidth: 300,
        placeholder: (_, __) => const SizedBox.expand(),
        // Server poster missing → fall back to an on-device frame.
        errorWidget: (_, __, ___) => _fromVideo(),
      );
    }
    return _fromVideo();
  }

  Widget _fromVideo() {
    if (videoUrl.isEmpty) return const _Fallback();
    return FutureBuilder<Uint8List?>(
      future: _frame(videoUrl),
      builder: (_, snap) {
        if (snap.connectionState != ConnectionState.done) {
          // Let the dark parent show through while the frame is generated.
          return const SizedBox.expand();
        }
        final bytes = snap.data;
        if (bytes == null || bytes.isEmpty) return const _Fallback();
        return Image.memory(bytes, fit: fit);
      },
    );
  }
}

/// Shown when there is neither a server poster nor an extractable frame — a
/// clear, intentional placeholder (not a blank black rectangle).
class _Fallback extends StatelessWidget {
  const _Fallback();
  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFF262626),
        child: const Center(
          child: Icon(Icons.movie_creation_outlined, color: Colors.white54, size: 30),
        ),
      );
}
