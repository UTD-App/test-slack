import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SvgRenderer extends StatelessWidget {
  final File? file;
  final String? assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final Color? color;

  const SvgRenderer.file(
    this.file, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.color,
  }) : assetPath = null;

  const SvgRenderer.asset(
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
    final colorFilter =
        color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null;

    if (assetPath != null) {
      return SvgPicture.asset(
        assetPath!,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        colorFilter: colorFilter,
      );
    }

    return SvgPicture.file(
      file!,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      colorFilter: colorFilter,
    );
  }
}
