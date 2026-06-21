import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:utd_app/shared/core/color_manager.dart';

import '../../domain/user_profile_model.dart';
import '../utils/media.dart';

/// Circular avatar. A decorative frame is overlaid ONLY when the frame package
/// supplies one (`profile.avatarFrame`) — nothing is hardcoded, so with no
/// frame package installed the avatar renders cleanly on its own and the box
/// shrinks to the avatar (no empty gap). The frame ignores pointer events so
/// taps still reach the avatar.
class ProfileAvatarFrame extends StatelessWidget {
  final UserProfileModel profile;

  /// When set, a camera badge is shown on the avatar's corner and tapping the
  /// avatar runs this (legacy inline-edit affordance). Null on other users'.
  final VoidCallback? onEdit;

  /// When set, tapping the avatar runs this instead of [onEdit] and NO camera
  /// badge is shown — used on the own profile to open the visitor preview.
  final VoidCallback? onTap;

  const ProfileAvatarFrame({
    super.key,
    required this.profile,
    this.onEdit,
    this.onTap,
  });

  bool get _hasAvatar => profile.avatar != null && profile.avatar!.isNotEmpty;
  String? get _frameUrl => profile.avatarFrame;

  @override
  Widget build(BuildContext context) {
    final hasFrame = _frameUrl != null;
    final avatarSize = 96.w;
    final frameSize = 140.w;
    final boxSize = hasFrame ? frameSize : avatarSize;
    // Inset from the box edge to the avatar's edge (the avatar is centred).
    final inset = (boxSize - avatarSize) / 2;

    final content = SizedBox(
      width: boxSize,
      height: boxSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: ColorManager.navSelectedGradient, // purple → pink ring
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: ColorManager.lumiaAccent.withValues(alpha: 0.40),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ColorManager.lumiaCardBg,
                border: Border.all(color: ColorManager.lumiaBgDark, width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: _hasAvatar
                  ? CachedNetworkImage(
                      imageUrl: resolveMediaUrl(profile.avatar),
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _loading(),
                      errorWidget: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          if (hasFrame)
            IgnorePointer(
              child: CachedNetworkImage(
                imageUrl: resolveMediaUrl(_frameUrl),
                width: frameSize,
                height: frameSize,
                fit: BoxFit.contain,
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          if (onEdit != null)
            Positioned(
              bottom: inset,
              right: inset,
              // Its own tap target so the badge can EDIT the photo while a tap
              // on the avatar body runs [onTap] (e.g. open the full profile).
              // Nested deeper than the body's GestureDetector, so it wins hit
              // testing within its bounds.
              child: GestureDetector(onTap: onEdit, child: _cameraBadge()),
            ),
        ],
      ),
    );

    // Body tap: prefer the explicit [onTap] (open profile / visitor-preview),
    // falling back to [onEdit] so the legacy edit-on-tap behaviour is preserved
    // when no [onTap] is supplied.
    final tap = onTap ?? onEdit;
    if (tap == null) return content;
    return GestureDetector(onTap: tap, child: content);
  }

  Widget _cameraBadge() => Container(
        padding: EdgeInsets.all(5.w),
        decoration: BoxDecoration(
          color: ColorManager.lumiaAccent,
          shape: BoxShape.circle,
          border: Border.all(color: ColorManager.lumiaCardBg, width: 2),
        ),
        child: Icon(Icons.camera_alt, size: 14.sp, color: Colors.white),
      );

  Widget _placeholder() => Icon(
        Icons.person,
        size: 48.sp,
        color: ColorManager.lumiaTextSecondary,
      );

  Widget _loading() => Center(
        child: SizedBox(
          width: 22.w,
          height: 22.w,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: ColorManager.lumiaAccent,
          ),
        ),
      );
}
