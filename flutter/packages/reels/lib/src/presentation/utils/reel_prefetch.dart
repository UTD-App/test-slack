import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Pre-downloads upcoming reel videos into the on-disk cache so they play
/// instantly (from a local file) the moment they scroll into view — the
/// TikTok-style "no loading between videos" behaviour.
///
/// Best-effort: failures are swallowed and a reel simply streams from the
/// network if its file isn't cached yet.
class ReelPrefetch {
  ReelPrefetch._();

  /// Dedicated cache for reel videos with a hard cap so prefetched clips can't
  /// fill the device's storage. DefaultCacheManager keeps 200 objects for 30
  /// days — far too much for multi-MB videos. The player reads cached files
  /// through [cachedFile], so it MUST share this same manager/key.
  static final CacheManager _cache = CacheManager(
    Config(
      'reelsVideoCache',
      maxNrOfCacheObjects: 40,
      stalePeriod: const Duration(days: 3),
    ),
  );

  /// URLs currently downloading — avoids firing the same download twice.
  static final Set<String> _inFlight = {};

  /// URLs already cached this session — lets [warm] skip no-op work.
  static final Set<String> _done = {};

  /// URLs a player is currently streaming from the network. We skip prefetching
  /// these so the same bytes aren't pulled twice (once by the player, once by
  /// the cache manager). See ReelPlayerItem._ensureController.
  static final Set<String> _streaming = {};

  /// Mark/clear a URL the player is streaming directly so [warm] leaves it alone.
  static void markStreaming(String url) {
    if (url.isNotEmpty) _streaming.add(url);
  }

  static void clearStreaming(String url) => _streaming.remove(url);

  /// Warm the cache for [urls] (already-resolved absolute URLs).
  static void warm(Iterable<String> urls) {
    for (final url in urls) {
      if (url.isEmpty ||
          _inFlight.contains(url) ||
          _done.contains(url) ||
          _streaming.contains(url)) {
        continue;
      }
      _inFlight.add(url);
      _download(url);
    }
  }

  static Future<void> _download(String url) async {
    try {
      // getSingleFile returns the cached file, downloading only if missing.
      await _cache.getSingleFile(url);
      _done.add(url);
    } catch (_) {
      // best-effort — the reel will just stream instead.
    } finally {
      _inFlight.remove(url);
    }
  }

  /// The cached local file for [url], or null if it hasn't been prefetched yet.
  static Future<File?> cachedFile(String url) async {
    if (url.isEmpty) return null;
    try {
      final info = await _cache.getFileFromCache(url);
      return info?.file;
    } catch (_) {
      return null;
    }
  }
}
