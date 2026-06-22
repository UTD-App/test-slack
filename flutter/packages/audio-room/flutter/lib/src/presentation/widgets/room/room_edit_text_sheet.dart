import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

const _bgDark = Color(0xFF1A1028);
const _cardBg = Color(0xFF2A1840);
const _textPrimary = Color(0xFFFFFFFF);
const _textSecondary = Color(0xFFB8A5CC);
const _accent = Color(0xFFB44AFF);

void showEditTextSheet(
  BuildContext context, {
  required String title,
  required String initialValue,
  required ValueChanged<String> onSave,
  int maxLines = 1,
  int? maxLength,
}) {
  final controller = TextEditingController(text: initialValue);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: _cardBg,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(ctx).viewInsets.bottom,
        left: 16.w,
        right: 16.w,
        top: 16.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  onSave(controller.text.trim());
                  Navigator.pop(ctx);
                },
                child: Text('حفظ', style: TextStyle(color: _accent)),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: controller,
            maxLines: maxLines,
            maxLength: maxLength,
            autofocus: true,
            style: const TextStyle(color: _textPrimary),
            decoration: InputDecoration(
              filled: true,
              fillColor: _bgDark,
              counterStyle: const TextStyle(color: _textSecondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SizedBox(height: 16.h),
        ],
      ),
    ),
  );
}
