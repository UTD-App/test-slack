import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'room_theme.dart';

class DefaultOptionTile extends StatelessWidget {
  final String label;
  final String assetPath;
  final bool isSelected;
  final VoidCallback onTap;

  const DefaultOptionTile({
    super.key,
    required this.label,
    required this.assetPath,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? RoomTheme.accent.withValues(alpha: 0.15) : RoomTheme.cardBg,
          borderRadius: BorderRadius.circular(10.r),
          border: isSelected
              ? Border.all(color: RoomTheme.accent)
              : Border.all(color: RoomTheme.textSecondary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Image.asset(
              assetPath,
              width: 28.r,
              height: 28.r,
            ),
            SizedBox(width: 10.w),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? RoomTheme.accent : RoomTheme.textPrimary,
                fontSize: 15.sp,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_circle, color: RoomTheme.accent, size: 20.r),
          ],
        ),
      ),
    );
  }
}
