import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:utd_app/localization/localization.dart';

import '../../../../audio_room_strings.dart';
import '../shared/room_theme.dart';

enum RoomBackgroundOption { change, reset }

Future<RoomBackgroundOption?> showRoomBackgroundSheet(
  BuildContext context, {
  bool hasBackground = false,
}) {
  return showModalBottomSheet<RoomBackgroundOption>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _RoomBackgroundSheetBody(hasBackground: hasBackground),
  );
}

class _RoomBackgroundSheetBody extends StatelessWidget {
  final bool hasBackground;

  const _RoomBackgroundSheetBody({required this.hasBackground});

  @override
  Widget build(BuildContext context) {
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
              context.tr(AudioRoomKeys.background),
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16.h),
            ListTile(
              leading: Icon(Icons.wallpaper_rounded, color: RoomTheme.accent, size: 24.r),
              title: Text(context.tr(AudioRoomKeys.changeBackground), style: const TextStyle(color: Colors.white)),
              trailing: Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14.r),
              onTap: () => Navigator.pop(context, RoomBackgroundOption.change),
            ),
            if (hasBackground) ...[
              Divider(color: Colors.white.withValues(alpha: 0.1), indent: 56.w),
              ListTile(
                leading: Icon(Icons.restore_rounded, color: RoomTheme.accent, size: 24.r),
                title: Text(context.tr(AudioRoomKeys.resetBackground), style: const TextStyle(color: Colors.white)),
                trailing: Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14.r),
                onTap: () => Navigator.pop(context, RoomBackgroundOption.reset),
              ),
            ],
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }
}
