import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:utd_app/localization/localization.dart';
import 'package:utd_app/shared/core/color_manager.dart';
import 'package:utd_app/shared/media/app_cache_manager.dart';

import '../utils/media.dart';

/// The swipeable, multi-image cover banner shown at the top of a profile.
///
/// • With covers: a full-width [PageView] paged between images with dot
///   indicators; tapping opens a fullscreen pinch-to-zoom viewer.
/// • Empty + editable (own profile): a tappable "add cover" placeholder.
/// • Empty + not editable (visited profile): nothing — the page keeps its
///   gradient background, exactly as before.
///
/// When [onEdit] is set (own profile) a camera button floats on the banner so
/// the user can manage their covers.
class ProfileCoverBanner extends StatefulWidget {
  /// Resolved or raw cover paths/URLs (passed through [resolveMediaUrl]).
  final List<String> covers;

  /// Raw, immutable storage paths parallel to [covers]. Used as the stable
  /// cache key (and preferred image source) so the disk cache survives host /
  /// signed-URL changes and resolves through the app domain like the rest of
  /// the app — matching the avatar media-resolution convention.
  final List<String> coverPaths;

  /// Banner height. The avatar overlaps the bottom edge in the parent layout.
  final double height;

  /// Own-profile manage-covers callback. Null on visited profiles.
  final VoidCallback? onEdit;

  const ProfileCoverBanner({
    super.key,
    required this.covers,
    this.coverPaths = const [],
    this.height = 190,
    this.onEdit,
  });

  @override
  State<ProfileCoverBanner> createState() => _ProfileCoverBannerState();
}

class _ProfileCoverBannerState extends State<ProfileCoverBanner> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Stable identity for cover [i]: prefer the immutable storage path (so the
  /// cache key and host stay constant across reloads) and fall back to the
  /// already-resolved URL when no path is available.
  String _src(int i) {
    if (i < widget.coverPaths.length && widget.coverPaths[i].isNotEmpty) {
      return widget.coverPaths[i];
    }
    return widget.covers[i];
  }

  @override
  Widget build(BuildContext context) {
    final covers = widget.covers;
    final h = widget.height.h;

    if (covers.isEmpty) {
      // Visited profile with no cover → render nothing (keep the gradient).
      if (widget.onEdit == null) return SizedBox(height: h);
      return _emptyPlaceholder(context, h);
    }

    // Decode the (potentially multi-MB) cover at roughly the banner's pixel
    // width instead of full resolution — far faster to display and avoids the
    // out-of-memory decode failures that show up as a "broken" image.
    final mq = MediaQuery.of(context);
    final cacheW = (mq.size.width * mq.devicePixelRatio).round();

    return SizedBox(
      height: h,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: covers.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => _openViewer(context, i),
              child: CachedNetworkImage(
                // Display the backend-resolved URL (covers[i]) — already absolute
                // and correctly bucketed (e.g. GCS). _src(i) (the raw storage path)
                // is only a STABLE CACHE KEY; using it as the image URL resolved to
                // a LOCAL /storage/<path> that 404s when media lives on a cloud
                // bucket → the banner showed nothing.
                imageUrl: resolveMediaUrl(covers[i]),
                cacheKey: _src(i),
                cacheManager: AppCacheManager.instance.manager,
                fit: BoxFit.cover,
                memCacheWidth: cacheW,
                maxWidthDiskCache: 1080,
                fadeInDuration: const Duration(milliseconds: 200),
                placeholder: (_, __) => _loading(),
                errorWidget: (_, __, ___) => _broken(),
              ),
            ),
          ),
          // Subtle bottom scrim so the overlapping avatar + dots stay legible.
          IgnorePointer(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0x66000000)],
                  stops: [0.55, 1.0],
                ),
              ),
            ),
          ),
          if (covers.length > 1)
            Positioned(
              bottom: 10.h,
              left: 0,
              right: 0,
              child: _dots(covers.length),
            ),
          if (widget.onEdit != null)
            // Pin the camera to the LEADING corner (start) so it sits opposite
            // the top-bar edit pencil — which is the trailing item of an
            // RTL-aware Row. With an absolute right: the pencil overlapped this
            // button in LTR (English); start: keeps them on opposite corners in
            // both directions (camera top-right in AR, top-left in EN).
            PositionedDirectional(
              top: 8.h,
              start: 12.w,
              child: _editButton(),
            ),
        ],
      ),
    );
  }

  Widget _emptyPlaceholder(BuildContext context, double h) {
    return GestureDetector(
      onTap: widget.onEdit,
      child: Container(
        height: h,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: ColorManager.navSelectedGradient,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, size: 30.sp, color: Colors.white),
            SizedBox(height: 8.h),
            Text(
              context.tr('profile.add_cover'),
              style: TextStyle(
                color: Colors.white,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dots(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == _page;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.symmetric(horizontal: 3.w),
          width: active ? 18.w : 7.w,
          height: 7.w,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(4.r),
          ),
        );
      }),
    );
  }

  Widget _editButton() {
    return GestureDetector(
      onTap: widget.onEdit,
      child: Container(
        padding: EdgeInsets.all(7.w),
        decoration: BoxDecoration(
          color: ColorManager.lumiaCardBg.withValues(alpha: 0.7),
          shape: BoxShape.circle,
          border: Border.all(color: ColorManager.lumiaCardBorder),
        ),
        child: Icon(Icons.camera_alt, size: 16.sp, color: Colors.white),
      ),
    );
  }

  Widget _loading() => Container(
        color: ColorManager.lumiaCardBg,
        child: Center(
          child: SizedBox(
            width: 22.w,
            height: 22.w,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: ColorManager.lumiaAccent,
            ),
          ),
        ),
      );

  Widget _broken() => Container(
        color: ColorManager.lumiaCardBg,
        child: Icon(
          Icons.broken_image_outlined,
          size: 32.sp,
          color: ColorManager.lumiaTextSecondary,
        ),
      );

  /// Fullscreen, swipeable, pinch-to-zoom viewer for the covers.
  void _openViewer(BuildContext context, int initial) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      builder: (ctx) {
        final pc = PageController(initialPage: initial);
        return Stack(
          children: [
            PageView.builder(
              controller: pc,
              itemCount: widget.covers.length,
              itemBuilder: (_, i) => InteractiveViewer(
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: resolveMediaUrl(widget.covers[i]),
                    cacheKey: _src(i),
                    cacheManager: AppCacheManager.instance.manager,
                    fit: BoxFit.contain,
                    maxWidthDiskCache: 1920,
                    errorWidget: (_, __, ___) =>
                        Icon(Icons.broken_image_outlined,
                            size: 48.sp, color: Colors.white54),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(ctx).padding.top + 8,
              right: 12,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        );
      },
    );
  }
}
