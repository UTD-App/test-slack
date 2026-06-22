import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

const _bgDark = Color(0xFF1A1028);
const _cardBg = Color(0xFF2A1840);
const _textPrimary = Color(0xFFFFFFFF);
const _textSecondary = Color(0xFFB8A5CC);
const _accent = Color(0xFFB44AFF);

Future<String?> showRoomPasswordDialog(BuildContext context) async {
  final controller = TextEditingController();
  return showDialog<String?>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: _cardBg,
      title: const Text(
        'كلمة مرور الغرفة',
        style: TextStyle(color: _textPrimary),
      ),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        maxLength: 6,
        style: const TextStyle(color: _textPrimary),
        decoration: InputDecoration(
          hintText: 'ادخل كلمة المرور (6 أرقام)',
          hintStyle: const TextStyle(color: _textSecondary),
          counterStyle: const TextStyle(color: _textSecondary),
          filled: true,
          fillColor: _bgDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('إلغاء', style: TextStyle(color: _textSecondary)),
        ),
        TextButton(
          onPressed: () {
            final text = controller.text.trim();
            if (text.isNotEmpty) {
              Navigator.pop(ctx, text);
            }
          },
          child: Text('تأكيد', style: TextStyle(color: _accent)),
        ),
      ],
    ),
  );
}

Future<bool> showRemovePasswordDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: _cardBg,
      title: const Text(
        'إزالة كلمة المرور',
        style: TextStyle(color: _textPrimary),
      ),
      content: const Text(
        'هل تريد إزالة كلمة المرور من الغرفة؟',
        style: TextStyle(color: _textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('إلغاء', style: TextStyle(color: _textSecondary)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('إزالة'),
        ),
      ],
    ),
  );
  return result ?? false;
}
