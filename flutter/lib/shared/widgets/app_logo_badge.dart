import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/color_manager.dart';
import 'app_logo.dart';

/// The app logo presented as a clean **circular badge** — a white disc ringed by
/// a soft accent glow.
///
/// Logo artwork commonly ships on a white background; rendered raw over the
/// purple gradient that reads as a hard white *square*. Clipping it into a white
/// disc turns it into a deliberate round logo badge instead. Wraps [AppLogo], so
/// the admin-managed logo + asset-fallback behaviour is preserved.
class AppLogoBadge extends StatelessWidget {
  /// Diameter of the badge (logical px; scaled with screenutil).
  final double size;

  /// Shown while the network logo loads / on error / when no admin logo is set
  /// — typically `Image.asset(AssetManager.logo, fit: BoxFit.contain)`.
  final Widget fallback;

  const AppLogoBadge({
    super.key,
    required this.size,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final d = size.w;
    // Inset the artwork from the disc edge so it never touches the rim.
    final inner = d * 0.72;
    return Container(
      width: d,
      height: d,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: ColorManager.lumiaAccent.withValues(alpha: 0.45),
            blurRadius: 40,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: Container(
          width: d,
          height: d,
          color: ColorManager.white,
          alignment: Alignment.center,
          child: AppLogo(
            width: inner,
            height: inner,
            fit: BoxFit.contain,
            fallback: SizedBox(width: inner, height: inner, child: fallback),
          ),
        ),
      ),
    );
  }
}
