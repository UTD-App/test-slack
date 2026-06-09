import 'dart:io';

import 'package:flutter/material.dart';

import 'app_cache_manager.dart';
import 'image_type.dart';
import 'renderers/image_renderer.dart';
import 'renderers/svg_renderer.dart';
import 'renderers/svga_renderer.dart';

class DynamicImage extends StatefulWidget {
  final String source;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final Color? color;
  final bool isAsset;
  final Map<String, String>? headers;

  const DynamicImage({
    super.key,
    required this.source,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.color,
    this.isAsset = false,
    this.headers,
  });

  @override
  State<DynamicImage> createState() => _DynamicImageState();
}

class _DynamicImageState extends State<DynamicImage> {
  late ImageType _type;
  Future<File>? _fileFuture;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(DynamicImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source ||
        oldWidget.isAsset != widget.isAsset) {
      _resolve();
    }
  }

  void _resolve() {
    _type = ImageTypeResolver.resolve(widget.source);
    if (!widget.isAsset && _type != ImageType.unknown) {
      _fileFuture = AppCacheManager.instance
          .getFile(widget.source, headers: widget.headers);
    } else {
      _fileFuture = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_type == ImageType.unknown) {
      return _wrapClip(_buildError());
    }

    if (widget.isAsset) {
      return _wrapClip(_buildAsset());
    }

    // SVGA handles its own network loading + we pass the URL directly
    // so it can use its built-in caching. For cached files we still
    // pre-cache via AppCacheManager for consistency.
    if (_type == ImageType.svga) {
      return _wrapClip(
        SvgaRenderer.network(
          widget.source,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
        ),
      );
    }

    return FutureBuilder<File>(
      future: _fileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _wrapClip(_buildPlaceholder());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _wrapClip(_buildError());
        }

        return _wrapClip(_buildFromFile(snapshot.data!));
      },
    );
  }

  Widget _buildAsset() {
    return switch (_type) {
      ImageType.svg => SvgRenderer.asset(
          widget.source,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          alignment: widget.alignment,
          color: widget.color,
        ),
      ImageType.svga => SvgaRenderer.asset(
          widget.source,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
        ),
      ImageType.standard => ImageRenderer.asset(
          widget.source,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          alignment: widget.alignment,
          color: widget.color,
        ),
      ImageType.unknown => _buildError(),
    };
  }

  Widget _buildFromFile(File file) {
    return switch (_type) {
      ImageType.svg => SvgRenderer.file(
          file,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          alignment: widget.alignment,
          color: widget.color,
        ),
      ImageType.standard => ImageRenderer.file(
          file,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          alignment: widget.alignment,
          color: widget.color,
        ),
      // SVGA is handled before FutureBuilder, but included for exhaustiveness
      ImageType.svga => SvgaRenderer.file(
          file,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
        ),
      ImageType.unknown => _buildError(),
    };
  }

  Widget _buildPlaceholder() {
    return widget.placeholder ??
        SizedBox(
          width: widget.width,
          height: widget.height,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
  }

  Widget _buildError() {
    return widget.errorWidget ??
        SizedBox(
          width: widget.width,
          height: widget.height,
          child: const Center(child: Icon(Icons.broken_image_outlined)),
        );
  }

  Widget _wrapClip(Widget child) {
    if (widget.borderRadius == null) return child;
    return ClipRRect(borderRadius: widget.borderRadius!, child: child);
  }
}
