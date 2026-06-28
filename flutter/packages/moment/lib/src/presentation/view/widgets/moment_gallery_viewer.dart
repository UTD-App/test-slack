import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:utd_app/shared/media/app_cache_manager.dart';

/// Full-screen, swipeable image gallery: pinch/double-tap to zoom, swipe between
/// a moment's images, with a page counter. Images come from the shared on-disk
/// cache so they open instantly once seen in the feed.
class MomentGalleryViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const MomentGalleryViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  /// Pushes the viewer as an opaque full-screen route with a fade transition.
  static Future<void> open(
    BuildContext context, {
    required List<String> images,
    int initialIndex = 0,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) =>
            MomentGalleryViewer(images: images, initialIndex: initialIndex),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  State<MomentGalleryViewer> createState() => _MomentGalleryViewerState();
}

class _MomentGalleryViewerState extends State<MomentGalleryViewer> {
  late final PageController _controller =
      PageController(initialPage: widget.initialIndex);
  late int _current = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final multi = widget.images.length > 1;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            itemCount: widget.images.length,
            pageController: _controller,
            onPageChanged: (i) => setState(() => _current = i),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            loadingBuilder: (_, __) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            builder: (context, i) => PhotoViewGalleryPageOptions(
              imageProvider: CachedNetworkImageProvider(
                widget.images[i],
                cacheManager: AppCacheManager.instance.manager,
              ),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 3,
              initialScale: PhotoViewComputedScale.contained,
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
              ),
            ),
          ),
          // Close button (clears the status bar).
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: _RoundIconButton(
                  icon: Icons.close,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
          // Page counter (e.g. "2 / 4").
          if (multi)
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    // Force LTR so the counter reads "1 / 4" even in an RTL app
                    // (otherwise the whole string flips to "4 / 1").
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        '${_current + 1} / ${widget.images.length}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.5),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
