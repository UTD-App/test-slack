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

  /// Shown when the SVGA fails to decode (e.g. a corrupt/legacy-format file).
  /// Without it a failed decode would render nothing (a silent blank).
  final Widget? errorWidget;

  /// Loop the animation forever (true, default) or play it once (false).
  /// One-shot is used for things like a gift played full-screen on send.
  final bool repeat;

  /// Called once a one-shot animation (repeat == false) finishes playing.
  final VoidCallback? onFinished;

  const SvgaRenderer.file(
    this.file, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.errorWidget,
    this.repeat = true,
    this.onFinished,
  })  : assetPath = null,
        networkUrl = null;

  const SvgaRenderer.asset(
    this.assetPath, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.errorWidget,
    this.repeat = true,
    this.onFinished,
  })  : file = null,
        networkUrl = null;

  const SvgaRenderer.network(
    this.networkUrl, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.errorWidget,
    this.repeat = true,
    this.onFinished,
  })  : file = null,
        assetPath = null;

  @override
  State<SvgaRenderer> createState() => _SvgaRendererState();
}

class _SvgaRendererState extends State<SvgaRenderer>
    with SingleTickerProviderStateMixin {
  SVGAAnimationController? _controller;
  bool _failed = false;

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
      _failed = false;
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
        _controller!.videoItem = videoItem;
        if (widget.repeat) {
          _controller!.repeat();
        } else {
          _controller!.forward().whenComplete(() {
            if (mounted) widget.onFinished?.call();
          });
        }
      } else {
        videoItem.dispose();
      }
    } catch (e) {
      debugPrint('SvgaRenderer: failed to decode: $e');
      if (mounted) setState(() => _failed = true);
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
    if (_failed) {
      return widget.errorWidget ?? const SizedBox.shrink();
    }
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
