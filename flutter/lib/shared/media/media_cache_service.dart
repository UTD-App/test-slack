import 'dart:io';

import 'app_cache_manager.dart';

/// Unified media cache service for all file types.
/// Cache is permanent — files stay until app data is cleared
/// or the URL changes (which forces a new download).
///
/// Usage from any package:
///   final file = await MediaCacheService.instance.getSvga('https://...');
///   final file = await MediaCacheService.instance.getVideo('https://...');
///   final file = await MediaCacheService.instance.getImage('https://...');
class MediaCacheService {
  static final MediaCacheService instance = MediaCacheService._();
  MediaCacheService._();

  final _cache = AppCacheManager.instance;

  // ── SVGA ──────────────────────────────────────────────────────────────────

  /// Returns a cached SVGA file. Downloads once, stores permanently.
  Future<File> getSvga(String url) => _cache.getFile(url);

  /// Prefetch SVGA files in background (e.g. on room enter).
  Future<void> prefetchSvgas(List<String> urls) async {
    await Future.wait(urls.map(_cache.prefetch));
  }

  // ── MP4 Alpha ──────────────────────────────────────────────────────────────

  /// Returns a cached MP4 Alpha video file. Downloads once, stores permanently.
  Future<File> getVideo(String url) => _cache.getFile(url);

  /// Prefetch video files in background.
  Future<void> prefetchVideos(List<String> urls) async {
    await Future.wait(urls.map(_cache.prefetch));
  }

  // ── WebP / Images ──────────────────────────────────────────────────────────

  /// Returns a cached WebP or any image file.
  Future<File> getImage(String url, {Map<String, String>? headers}) {
    return _cache.getFile(url, headers: headers);
  }

  /// Prefetch images in background.
  Future<void> prefetchImages(List<String> urls) async {
    await Future.wait(urls.map(_cache.prefetch));
  }

  // ── General ────────────────────────────────────────────────────────────────

  /// Get any file by URL regardless of type.
  Future<File> getFile(String url, {Map<String, String>? headers}) {
    return _cache.getFile(url, headers: headers);
  }

  /// Remove a specific file from cache (when admin updates it).
  Future<void> invalidate(String url) => _cache.invalidate(url);

  /// Remove multiple files from cache.
  Future<void> invalidateAll(List<String> urls) async {
    await Future.wait(urls.map(_cache.invalidate));
  }

  /// Clear ALL media cache. Use with caution.
  Future<void> clearAll() => _cache.clearAll();
}
