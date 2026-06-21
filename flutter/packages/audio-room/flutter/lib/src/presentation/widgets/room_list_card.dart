import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../domain/room_model.dart';

class RoomListCard extends StatelessWidget {
  final RoomModel room;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final bool showFavorite;

  const RoomListCard({
    super.key,
    required this.room,
    this.onTap,
    this.onFavoriteTap,
    this.showFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14.r),
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            children: [
              SizedBox(
                width: 90.w,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (room.roomCover != null && room.roomCover!.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: room.roomCover!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _placeholder(),
                        errorWidget: (_, __, ___) => _placeholder(),
                      )
                    else
                      _placeholder(),
                    if (room.hasPassword)
                      Positioned(
                        top: 6.r,
                        left: 6.r,
                        child: Container(
                          padding: EdgeInsets.all(3.r),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Icon(Icons.lock_rounded, color: Colors.white, size: 11.r),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              room.roomName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                          if (showFavorite) ...[
                            SizedBox(width: 8.w),
                            GestureDetector(
                              onTap: onFavoriteTap,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                transitionBuilder: (child, anim) =>
                                    ScaleTransition(scale: anim, child: child),
                                child: Icon(
                                  room.isFavorite
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  key: ValueKey(room.isFavorite),
                                  color: room.isFavorite ? Colors.red : Colors.grey.shade400,
                                  size: 20.r,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          _OwnerAvatar(url: room.ownerAvatar, size: 18.r),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              room.ownerName ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people_alt_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 13.r,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '${room.visitorCount}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _placeholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey.shade300, Colors.grey.shade400],
        ),
      ),
      child: Center(
        child: Icon(Icons.mic_rounded, size: 28.r, color: Colors.white54),
      ),
    );
  }
}

class _OwnerAvatar extends StatelessWidget {
  final String? url;
  final double size;
  const _OwnerAvatar({this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: url!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => CircleAvatar(
            radius: size / 2,
            backgroundColor: Colors.grey.shade500,
            child: Icon(Icons.person, size: size * 0.6, color: Colors.white70),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Colors.grey.shade500,
      child: Icon(Icons.person, size: size * 0.6, color: Colors.white70),
    );
  }
}
