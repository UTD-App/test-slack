import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../domain/room_model.dart';
import 'room_badge.dart';
import 'room_cover_image.dart';

class RoomCard extends StatelessWidget {
  final RoomModel room;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final bool showFavorite;

  const RoomCard({
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
          borderRadius: BorderRadius.circular(16.r),
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  RoomCoverImage(url: room.roomCover),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.4),
                          ],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                  if (room.hasPassword)
                    Positioned(
                      top: 8.r,
                      left: 8.r,
                      child: RoomBadge(
                        child: Icon(Icons.lock_rounded, color: Colors.white, size: 12.r),
                      ),
                    ),
                  Positioned(
                    top: 8.r,
                    right: 8.r,
                    child: RoomBadge(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_alt_rounded, color: Colors.white, size: 11.r),
                          SizedBox(width: 3.w),
                          Text(
                            '${room.visitorCount}',
                            style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (showFavorite)
                    Positioned(
                      bottom: 8.r,
                      right: 8.r,
                      child: GestureDetector(
                        onTap: onFavoriteTap,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.all(6.r),
                          decoration: BoxDecoration(
                            color: room.isFavorite
                                ? Colors.red.withValues(alpha: 0.85)
                                : Colors.black.withValues(alpha: 0.45),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            room.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: Colors.white,
                            size: 14.r,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 8.r,
                    left: 8.r,
                    right: showFavorite ? 36.r : 8.r,
                    child: Row(
                      children: [
                        _OwnerAvatar(url: room.ownerAvatar, size: 20.r),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            room.ownerName ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              child: Text(
                room.roomName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.sp,
                ),
              ),
            ),
          ],
        ),
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
          errorWidget: (_, __, ___) => _avatarFallback(size),
        ),
      );
    }
    return _avatarFallback(size);
  }

  static Widget _avatarFallback(double size) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Colors.grey.shade500,
      child: Icon(Icons.person, size: size * 0.6, color: Colors.white70),
    );
  }
}
