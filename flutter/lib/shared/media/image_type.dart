import 'package:flutter/foundation.dart';

enum ImageType { standard, svg, svga, unknown }

class ImageTypeResolver {
  static const _standardExtensions = {
    'png',
    'jpg',
    'jpeg',
    'webp',
    'gif',
    'bmp',
    'tiff',
    'ico',
  };

  static ImageType resolve(String source) {
    final ext = _extractExtension(source);
    if (ext == null) return ImageType.unknown;

    if (ext == 'svg') return ImageType.svg;
    if (ext == 'svga') return ImageType.svga;
    if (_standardExtensions.contains(ext)) return ImageType.standard;

    return ImageType.unknown;
  }

  static String? _extractExtension(String source) {
    try {
      final uri = Uri.parse(source);
      final path = uri.hasScheme ? uri.path : source;
      final lastDot = path.lastIndexOf('.');
      if (lastDot == -1 || lastDot == path.length - 1) return null;

      final ext = path.substring(lastDot + 1).toLowerCase();
      // Guard against fragments or weird suffixes
      if (ext.contains('/') || ext.length > 10) return null;
      return ext;
    } catch (e) {
      debugPrint('ImageTypeResolver: failed to parse "$source": $e');
      return null;
    }
  }
}
