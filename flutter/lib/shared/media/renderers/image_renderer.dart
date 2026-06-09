import 'dart:io';

import 'package:flutter/material.dart';

class ImageRenderer extends StatelessWidget {
  final File? file;
  final String? assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final Color? color;

  const ImageRenderer.file(
    this.file, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.color,
  }) : assetPath = null;

  const ImageRenderer.asset(
    this.assetPath, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.color,
  }) : file = null;

  @override
  Widget build(BuildContext context) {
    if (assetPath != null) {
      return Image.asset(
        assetPath!,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        color: color,
        errorBuilder: (_, __, ___) => _errorFallback(),
      );
    }

    return Image.file(
      file!,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      color: color,
      errorBuilder: (_, __, ___) => _errorFallback(),
    );
  }

  Widget _errorFallback() => SizedBox(
        width: width,
        height: height,
        child: const Center(child: Icon(Icons.broken_image_outlined)),
      );
}
