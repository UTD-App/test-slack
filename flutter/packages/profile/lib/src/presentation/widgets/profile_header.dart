import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../domain/user_profile_model.dart';
import '../utils/media.dart';

class ProfileHeader extends StatelessWidget {
  final UserProfileModel profile;

  const ProfileHeader({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50.r,
            backgroundImage: _hasAvatar
                ? CachedNetworkImageProvider(resolveMediaUrl(profile.avatar))
                : null,
            child: _hasAvatar
                ? null
                : Icon(Icons.person, size: 50.r, color: colors.outline),
          ),
          SizedBox(height: 12.h),
          if (profile.name != null && profile.name!.isNotEmpty)
            Text(
              profile.name!,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              profile.bio!,
              style: textTheme.bodyMedium?.copyWith(color: colors.outline),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (profile.countryName != null ||
              profile.countryFlag != null) ...[
            SizedBox(height: 8.h),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (profile.countryFlag != null &&
                    profile.countryFlag!.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: resolveMediaUrl(profile.countryFlag),
                    width: 20.w,
                    height: 14.h,
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  ),
                if (profile.countryFlag != null &&
                    profile.countryName != null)
                  SizedBox(width: 6.w),
                if (profile.countryName != null &&
                    profile.countryName!.isNotEmpty)
                  Text(
                    profile.countryName!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.outline,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  bool get _hasAvatar =>
      profile.avatar != null && profile.avatar!.isNotEmpty;
}
