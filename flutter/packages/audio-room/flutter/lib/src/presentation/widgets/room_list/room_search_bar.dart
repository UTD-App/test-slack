import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:utd_app/localization/localization.dart';

import '../../../audio_room_strings.dart';

class RoomSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const RoomSearchBar({super.key, required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.grey.shade200,
          ),
        ),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: context.tr(AudioRoomKeys.searchByNameOrId),
            hintStyle: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: 12.w, right: 8.w),
              child: Icon(
                Icons.search_rounded,
                size: 20.r,
                color: Colors.grey.shade400,
              ),
            ),
            prefixIconConstraints: BoxConstraints(minWidth: 40.w),
            suffixIcon: ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                if (controller.text.isEmpty) return const SizedBox.shrink();
                return GestureDetector(
                  onTap: () {
                    controller.clear();
                    onChanged('');
                  },
                  child: Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: Container(
                      width: 24.r,
                      height: 24.r,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 14.r,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
            suffixIconConstraints: BoxConstraints(minWidth: 32.w),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12.h),
          ),
          style: TextStyle(fontSize: 14.sp),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
