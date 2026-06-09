import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:utd_app/shared/core/color_manager.dart';
import 'package:utd_app/shared/widgets/button_widget.dart';
import 'package:utd_app/shared/widgets/text_widget.dart';

/// App-themed confirmation dialog — matches the app's look (rounded card, themed
/// colors + [ButtonWidget]/[TextWidget]) instead of the bare Material
/// AlertDialog. Returns true when the user confirms.
Future<bool> showThemedConfirm(
  BuildContext context, {
  required String title,
  required String confirmText,
  required String cancelText,
  String? message,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: ColorManager.white,
      insetPadding: EdgeInsets.symmetric(horizontal: 32.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextWidget(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                color: ColorManager.blackColor,
              ),
            ),
            if (message != null && message.isNotEmpty) ...[
              SizedBox(height: 8.h),
              TextWidget(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.sp, color: ColorManager.greyTextColor),
              ),
            ],
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: ButtonWidget(
                    title: cancelText,
                    onPressed: () => Navigator.pop(ctx, false),
                    backgroundColor: ColorManager.offWhite,
                    titleColor: ColorManager.blackColor,
                    borderColor: ColorManager.lightGray,
                    borderWidth: 1,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ButtonWidget(
                    title: confirmText,
                    onPressed: () => Navigator.pop(ctx, true),
                    backgroundColor: destructive ? ColorManager.error : ColorManager.primary,
                    titleColor: ColorManager.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}
