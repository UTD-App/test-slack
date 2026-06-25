import 'dart:async';

import 'package:flutter/material.dart';
import 'package:utd_app/shared/media/dynamic_image.dart';
import 'package:utd_app/shared/media/image_type.dart';
import 'package:utd_app/shared/media/renderers/svga_renderer.dart';

/// Plays a sent gift's animation full-screen over the whole app, then dismisses
/// itself — mirrors the big app, where a gift sent on a moment animates over the
/// screen. Driven from the gift picker on a successful send, so any host feature
/// (Moment, Reels…) gets it for free without depending on this package.
///
/// It inserts into the ROOT overlay, so it survives the gift sheet closing. SVGA
/// plays once and removes on completion; a static/animated raster shows briefly.
/// A hard fallback timer guarantees removal even if decoding stalls or fails.
class GiftPlayOverlay {
  GiftPlayOverlay._();

  /// [overlay] should be the ROOT overlay, captured BEFORE the gift sheet is
  /// popped (e.g. `Overlay.of(context, rootOverlay: true)`), so the animation
  /// outlives the closing sheet.
  static void play(
    OverlayState overlay, {
    required String source,
    String imageType = '',
  }) {
    if (source.isEmpty || !source.startsWith('http')) return;

    late OverlayEntry entry;
    var removed = false;
    void remove() {
      if (removed) return;
      removed = true;
      entry.remove();
    }

    entry = OverlayEntry(
      builder: (_) => _GiftPlayer(
        source: source,
        imageType: imageType,
        onDone: remove,
      ),
    );
    overlay.insert(entry);
  }
}

class _GiftPlayer extends StatefulWidget {
  final String source;
  final String imageType;
  final VoidCallback onDone;

  const _GiftPlayer({
    required this.source,
    required this.imageType,
    required this.onDone,
  });

  @override
  State<_GiftPlayer> createState() => _GiftPlayerState();
}

class _GiftPlayerState extends State<_GiftPlayer> {
  Timer? _fallback;
  var _done = false;

  bool get _isSvga =>
      widget.imageType.toLowerCase() == 'svga' ||
      ImageTypeResolver.resolve(widget.source) == ImageType.svga;

  @override
  void initState() {
    super.initState();
    // SVGA removes itself via onFinished; this is only a safety cap. A static
    // image has no completion signal, so the timer is its actual lifetime.
    _fallback = Timer(
      Duration(milliseconds: _isSvga ? 8000 : 2200),
      _finish,
    );
  }

  void _finish() {
    if (_done) return;
    _done = true;
    _fallback?.cancel();
    widget.onDone();
  }

  @override
  void dispose() {
    _fallback?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final Widget child = _isSvga
        ? SvgaRenderer.network(
            widget.source,
            width: size.width,
            height: size.height,
            fit: BoxFit.contain,
            repeat: false,
            onFinished: _finish,
            errorWidget: const SizedBox.shrink(),
          )
        : SizedBox(
            width: size.width * 0.6,
            child: DynamicImage(
              source: widget.source,
              fit: BoxFit.contain,
              errorWidget: const SizedBox.shrink(),
            ),
          );

    // IgnorePointer: the animation is decorative — it must never trap taps.
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(child: child),
      ),
    );
  }
}
