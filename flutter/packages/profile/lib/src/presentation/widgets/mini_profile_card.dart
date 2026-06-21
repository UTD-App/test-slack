import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../profile_routes.dart';
import '../utils/media.dart';

class MiniProfileCard extends StatelessWidget {
  final int userId;
  final String name;
  final String? avatar;
  final String? countryFlag;
  final bool isOnline;
  final VoidCallback? onTap;

  const MiniProfileCard({
    super.key,
    required this.userId,
    required this.name,
    this.avatar,
    this.countryFlag,
    this.isOnline = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap ?? () => context.push(ProfileRoutes.profilePath(userId)),
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 22.r,
                  backgroundImage: _hasAvatar
                      ? CachedNetworkImageProvider(resolveMediaUrl(avatar))
                      : null,
                  child: _hasAvatar
                      ? null
                      : Icon(
                          Icons.person,
                          size: 22.r,
                          color: colors.outline,
                        ),
                ),
                if (isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12.r,
                      height: 12.r,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colors.surface,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                name,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (countryFlag != null && countryFlag!.isNotEmpty) ...[
              SizedBox(width: 8.w),
              CachedNetworkImage(
                imageUrl: resolveMediaUrl(countryFlag),
                width: 20.w,
                height: 14.h,
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool get _hasAvatar => avatar != null && avatar!.isNotEmpty;
}
