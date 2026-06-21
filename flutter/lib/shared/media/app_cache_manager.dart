import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class AppCacheManager {
  static final AppCacheManager instance = AppCacheManager._();

  static const String _cacheKey = 'utd_media_cache';
  static const int _maxCacheObjects = 500;
  static const Duration _stalePeriod = Duration(days: 7);

  late final CacheManager _manager;
  bool _initialized = false;

  AppCacheManager._();

  void init() {
    if (_initialized) return;
    // Must be an ImageCacheManager: cached_network_image asserts (and THROWS in
    // debug builds) when maxWidthDiskCache/maxHeightDiskCache is set on a plain
    // CacheManager. The profile cover banner uses maxWidthDiskCache, so a plain
    // CacheManager made every cover image fail to load (broken icon) in debug.
    _manager = _UtdImageCacheManager(
      Config(
        _cacheKey,
        stalePeriod: _stalePeriod,
        maxNrOfCacheObjects: _maxCacheObjects,
      ),
    );
    _initialized = true;
  }

  CacheManager get manager {
    assert(_initialized, 'AppCacheManager.init() must be called first');
    return _manager;
  }

  /// Returns a cached [File], downloading it first if not in cache.
  /// Concurrent calls for the same [url] share a single download.
  Future<File> getFile(String url, {Map<String, String>? headers}) async {
    final info = await _manager.getSingleFile(url, headers: headers);
    return info;
  }

  /// Returns a stream of [FileResponse] for progress tracking.
  Stream<FileResponse> getFileStream(
    String url, {
    Map<String, String>? headers,
  }) {
    return _manager.getFileStream(url, headers: headers);
  }

  /// Removes a single cached entry.
  Future<void> invalidate(String url) => _manager.removeFile(url);

  /// Clears the entire media cache.
  Future<void> clearAll() => _manager.emptyCache();

  /// Downloads and caches a file without returning it.
  Future<void> prefetch(String url) async {
    await _manager.downloadFile(url);
  }
}

/// A [CacheManager] that also supports cached_network_image's on-the-fly image
/// resizing (maxWidthDiskCache/maxHeightDiskCache) via the [ImageCacheManager]
/// mixin. Without this, setting those options throws an assertion in debug.
class _UtdImageCacheManager extends CacheManager with ImageCacheManager {
  _UtdImageCacheManager(super.config);
}
