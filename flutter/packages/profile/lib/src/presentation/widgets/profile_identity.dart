import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:utd_app/localization/localization.dart';
import 'package:utd_app/shared/core/color_manager.dart';

import '../../domain/user_profile_model.dart';
import '../../profile_strings.dart';
import '../utils/media.dart';
import 'profile_assets.dart';

/// Name + gender + country flag, the "ID: nnnn" copy row, and the two
/// level badges (wealth + charm).
class ProfileIdentity extends StatelessWidget {
  final UserProfileModel profile;

  /// When set (own profile), a pencil appears next to the name and tapping it
  /// opens a quick inline editor. Null on other users' profiles.
  final VoidCallback? onEditName;

  /// When set (own profile), the bio can be tapped to edit, and an "Add a bio"
  /// hint is shown when it's empty.
  final VoidCallback? onEditBio;

  /// When set (own profile), tapping the name runs this — used to open the
  /// visitor preview (name editing lives in the top-bar pencil → edit screen).
  final VoidCallback? onTap;

  /// Left-align the identity (name / ID / levels) instead of centering it —
  /// used by the side-by-side header on the full own profile.
  final bool alignStart;

  /// Whether to render the bio block. Off in the side header (the bio is shown
  /// elsewhere there).
  final bool showBio;

  const ProfileIdentity({
    super.key,
    required this.profile,
    this.onEditName,
    this.onEditBio,
    this.onTap,
    this.alignStart = false,
    this.showBio = true,
  });

  @override
  Widget build(BuildContext context) {
    final mainAlign =
        alignStart ? MainAxisAlignment.start : MainAxisAlignment.center;
    return Column(
      crossAxisAlignment:
          alignStart ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        // Name + gender + flag
        Row(
          mainAxisAlignment: mainAlign,
          children: [
            Flexible(
              child: GestureDetector(
                onTap: onTap,
                child: Text(
                  profile.name ?? context.tr(ProfileStrings.title),
                  style: TextStyle(
                    color: ColorManager.lumiaTextPrimary,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (onEditName != null) ...[
              SizedBox(width: 6.w),
              GestureDetector(
                onTap: onEditName,
                child: Icon(
                  Icons.edit,
                  size: 16.sp,
                  color: ColorManager.lumiaAccent,
                ),
              ),
            ],
            if (_genderIcon != null) ...[
              SizedBox(width: 6.w),
              _genderIcon!,
            ],
            if (profile.countryFlag != null &&
                profile.countryFlag!.isNotEmpty) ...[
              SizedBox(width: 6.w),
              ClipRRect(
                borderRadius: BorderRadius.circular(3.r),
                child: CachedNetworkImage(
                  imageUrl: resolveMediaUrl(profile.countryFlag),
                  width: 22.w,
                  height: 15.h,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 6.h),
        // ID + copy — the PUBLIC UID (not the internal DB id), matching search
        // and the admin dashboard. Falls back to "—" for legacy records with no
        // UID rather than leaking the database id.
        Builder(builder: (context) {
          final hasUid = profile.uuid != null && profile.uuid!.isNotEmpty;
          final displayUid = hasUid ? profile.uuid! : '—';
          return Row(
            mainAxisAlignment: mainAlign,
            children: [
              Text(
                '${context.tr(ProfileStrings.id)}: $displayUid',
                style: TextStyle(
                  color: ColorManager.lumiaTextSecondary,
                  fontSize: 12.sp,
                ),
              ),
              if (hasUid) ...[
                SizedBox(width: 4.w),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: displayUid));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.tr(ProfileStrings.copied))),
                    );
                  },
                  child: Icon(
                    Icons.copy,
                    size: 13.sp,
                    color: ColorManager.lumiaTextSecondary,
                  ),
                ),
              ],
            ],
          );
        }),
        // Level badges — shown only when the backend actually sends the
        // values (i.e. the level package is installed). No fabricated LV.0.
        if (profile.wealthLevel != null || profile.charmLevel != null) ...[
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: mainAlign,
            children: [
              if (profile.wealthLevel != null)
                _levelBadge(
                  icon: ProfileAssets.icLevel,
                  label: 'LV.${profile.wealthLevel}',
                  color: ColorManager.lumiaAccent,
                ),
              if (profile.wealthLevel != null && profile.charmLevel != null)
                SizedBox(width: 8.w),
              if (profile.charmLevel != null)
                _levelBadge(
                  icon: ProfileAssets.meCharm,
                  label: 'LV.${profile.charmLevel}',
                  color: const Color(0xFFCD7F32),
                ),
            ],
          ),
        ],
        // Bio — shown when present. On the own profile it's tappable to edit,
        // and an "Add a bio" hint shows when empty.
        if (showBio) ..._buildBio(context),
      ],
    );
  }

  List<Widget> _buildBio(BuildContext context) {
    final hasBio = profile.bio != null && profile.bio!.isNotEmpty;

    if (!hasBio) {
      if (onEditBio == null) return const [];
      // Own profile, no bio yet → invite the user to add one.
      return [
        SizedBox(height: 10.h),
        GestureDetector(
          onTap: onEditBio,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit, size: 14.sp, color: ColorManager.lumiaAccent),
              SizedBox(width: 4.w),
              Text(
                context.tr(ProfileStrings.addBio),
                style: TextStyle(
                  color: ColorManager.lumiaAccent,
                  fontSize: 13.sp,
                ),
              ),
            ],
          ),
        ),
      ];
    }

    final bioText = Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Text(
        profile.bio!,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: ColorManager.lumiaTextSecondary,
          fontSize: 13.sp,
        ),
      ),
    );

    return [
      SizedBox(height: 10.h),
      if (onEditBio == null)
        bioText
      else
        GestureDetector(
          onTap: onEditBio,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: bioText),
              SizedBox(width: 4.w),
              Icon(Icons.edit, size: 13.sp, color: ColorManager.lumiaAccent),
            ],
          ),
        ),
    ];
  }

  Widget? get _genderIcon {
    if (profile.gender == 1) {
      return Icon(Icons.male, size: 16.sp, color: const Color(0xFF42A5F5));
    }
    if (profile.gender == 2) {
      return Icon(Icons.female, size: 16.sp, color: const Color(0xFFEC407A));
    }
    return null;
  }

  Widget _levelBadge({
    required String icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            icon,
            width: 14.w,
            height: 14.w,
            errorBuilder: (_, __, ___) =>
                Icon(Icons.star, size: 14.sp, color: color),
          ),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
