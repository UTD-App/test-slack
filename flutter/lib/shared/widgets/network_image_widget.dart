import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../config/app_config.dart';

/// Convenience wrapper for [Image.network] that prepends [AppConfig.storageBucketUrl].
///
/// Pass just the image path (e.g. `"images/avatar.png"`);
/// the full URL is built automatically from [appConfig].
class NetworkImageWidget extends StatelessWidget {
  final double height;
  final double width;
  final String imagePath;
  final Color? color;
  final BoxFit? boxFit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const NetworkImageWidget({
    super.key,
    required this.height,
    required this.width,
    required this.imagePath,
    this.color,
    this.boxFit,
    this.placeholder,
    this.errorWidget,
  });

  String get _fullUrl => appConfig.storageUrl(imagePath);

  @override
  Widget build(BuildContext context) {
    final url = _fullUrl;

    if (imagePath.contains('.svg')) {
      return SvgPicture.network(
        url,
        height: height,
        width: width,
        colorFilter: color != null
            ? ColorFilter.mode(color!, BlendMode.srcIn)
            : null,
        fit: boxFit ?? BoxFit.contain,
        placeholderBuilder: placeholder != null ? (_) => placeholder! : null,
      );
    } else {
      return Image.network(
        url,
        height: height,
        width: width,
        color: color,
        fit: boxFit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ??
              SizedBox(
                height: height,
                width: width,
                child: const Center(child: CircularProgressIndicator()),
              );
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ??
              SizedBox(
                height: height,
                width: width,
                child: const Center(child: Icon(Icons.broken_image_outlined)),
              );
        },
      );
    }
  }
}
