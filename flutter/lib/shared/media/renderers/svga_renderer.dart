import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svga/flutter_svga.dart';

class SvgaRenderer extends StatefulWidget {
  final File? file;
  final String? assetPath;
  final String? networkUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const SvgaRenderer.file(
    this.file, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  })  : assetPath = null,
        networkUrl = null;

  const SvgaRenderer.asset(
    this.assetPath, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  })  : file = null,
        networkUrl = null;

  const SvgaRenderer.network(
    this.networkUrl, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  })  : file = null,
        assetPath = null;

  @override
  State<SvgaRenderer> createState() => _SvgaRendererState();
}

class _SvgaRendererState extends State<SvgaRenderer>
    with SingleTickerProviderStateMixin {
  SVGAAnimationController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = SVGAAnimationController(vsync: this);
    _decode();
  }

  @override
  void didUpdateWidget(covariant SvgaRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.networkUrl != widget.networkUrl ||
        oldWidget.assetPath != widget.assetPath ||
        oldWidget.file?.path != widget.file?.path) {
      _decode();
    }
  }

  Future<void> _decode() async {
    try {
      MovieEntity videoItem;
      if (widget.assetPath != null) {
        videoItem = await SVGAParser.shared.decodeFromAssets(widget.assetPath!);
      } else if (widget.file != null) {
        videoItem =
            await SVGAParser.shared.decodeFromURL(Uri.file(widget.file!.path).toString());
      } else if (widget.networkUrl != null) {
        videoItem =
            await SVGAParser.shared.decodeFromURL(widget.networkUrl!);
      } else {
        return;
      }

      if (mounted && _controller != null) {
        _controller!
          ..videoItem = videoItem
          ..repeat();
      } else {
        videoItem.dispose();
      }
    } catch (e) {
      debugPrint('SvgaRenderer: failed to decode: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) return const SizedBox.shrink();

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: SVGAImage(
        _controller!,
        fit: widget.fit,
      ),
    );
  }
}
