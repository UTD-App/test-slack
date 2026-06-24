import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:utd_app/localization/localization.dart';
import 'package:utd_app/shared/core/color_manager.dart';

import '../../domain/user_profile_model.dart';
import '../bloc/user_profile_bloc.dart';

/// Top bar over the gradient: circular back button (left) and, on the editable
/// OWN profile, a circular edit/pencil button (right) that opens the edit
/// screen. In visitor-preview of your own profile the pencil is hidden and a
/// small "preview" label is shown instead.
class ProfileTopBar extends StatelessWidget {
  final UserProfileModel profile;

  /// True only on the editable own profile (not in visitor preview). Gates the
  /// edit pencil.
  final bool isOwner;

  const ProfileTopBar({super.key, required this.profile, this.isOwner = false});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    // My own profile shown in read-only preview mode (is_me but not owner).
    final isPreview = profile.isMe && !isOwner;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (canPop)
            _circleButton(
              icon: Icons.arrow_back_ios_new,
              onTap: () => Navigator.of(context).maybePop(),
            )
          else
            SizedBox(width: 40.w),
          if (isPreview) _previewLabel(context),
          // Right cluster: an explicit Refresh button (complements pull-to-refresh,
          // which isn't obvious to users) + the edit pencil on the own profile.
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _circleButton(
                icon: Icons.refresh,
                onTap: () => _reload(context),
              ),
              if (isOwner) ...[
                SizedBox(width: 8.w),
                _circleButton(
                  icon: Icons.edit_outlined,
                  // Opens the server-driven edit-profile screen (`/profile` →
                  // StacDynamicScreen 'edit_profile'). The form self-sources its
                  // covers from the profile API, so no route args are needed.
                  onTap: () => context.push('/profile'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Re-fetch the profile (silent — no full-page loader). Wired to the explicit
  /// refresh button; the bloc skips the emit when data is unchanged.
  void _reload(BuildContext context) {
    context
        .read<UserProfileBloc>()
        .add(LoadUserProfileEvent(userId: profile.id, silent: true));
  }

  Widget _previewLabel(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: ColorManager.lumiaCardBg.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: ColorManager.lumiaCardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.visibility_outlined, color: Colors.white, size: 14.sp),
          SizedBox(width: 6.w),
          Text(
            context.tr('profile.preview_as_visitor'),
            style: TextStyle(color: Colors.white, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: ColorManager.lumiaCardBg.withValues(alpha: 0.7),
          shape: BoxShape.circle,
          border: Border.all(color: ColorManager.lumiaCardBorder),
        ),
        child: Icon(icon, color: Colors.white, size: 18.sp),
      ),
    );
  }
}
