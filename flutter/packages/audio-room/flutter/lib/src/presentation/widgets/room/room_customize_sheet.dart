import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'room_strings.dart';
import 'room_theme.dart';

enum RoomCustomizeOption { modes, background }

Future<RoomCustomizeOption?> showRoomCustomizeSheet(BuildContext context) {
  return showModalBottomSheet<RoomCustomizeOption>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => const _RoomCustomizeSheetBody(),
  );
}

class _RoomCustomizeSheetBody extends StatelessWidget {
  const _RoomCustomizeSheetBody();

  @override
  Widget build(BuildContext context) {
    final s = RoomStrings.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 8.h),
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              s.roomCustomize,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16.h),
            ListTile(
              leading: Icon(Icons.grid_view_rounded, color: RoomTheme.accent, size: 24.r),
              title: Text(s.seatModes, style: const TextStyle(color: Colors.white)),
              trailing: Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14.r),
              onTap: () => Navigator.pop(context, RoomCustomizeOption.modes),
            ),
            Divider(color: Colors.white.withValues(alpha: 0.1), indent: 56.w),
            ListTile(
              leading: Icon(Icons.wallpaper_rounded, color: RoomTheme.accent, size: 24.r),
              title: Text(s.changeBackground, style: const TextStyle(color: Colors.white)),
              trailing: Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14.r),
              onTap: () => Navigator.pop(context, RoomCustomizeOption.background),
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }
}
