import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../room/shared/room_theme.dart';
import 'setting_row.dart';

class TextSettingRow extends StatelessWidget {
  final String title;
  final String? value;
  final String placeholder;
  final double valueWidth;
  final bool canEdit;
  final VoidCallback? onTap;

  const TextSettingRow({
    super.key,
    required this.title,
    this.value,
    this.placeholder = '',
    this.valueWidth = 100,
    this.canEdit = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SettingRow(
      title: title,
      onTap: canEdit ? onTap : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: valueWidth.w,
            child: Text(
              value ?? placeholder,
              style: TextStyle(color: RoomTheme.textSecondary, fontSize: 14.sp),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
          if (canEdit) ...[
            SizedBox(width: 4.w),
            Icon(Icons.arrow_forward_ios, color: RoomTheme.textSecondary, size: 14.r),
          ],
        ],
      ),
    );
  }
}
