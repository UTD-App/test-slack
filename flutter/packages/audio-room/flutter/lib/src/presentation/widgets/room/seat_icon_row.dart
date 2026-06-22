import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'seat_icon_picker.dart';

class SeatIconRow extends StatelessWidget {
  final String label;
  final SeatIconChoice? choice;
  final VoidCallback onTap;
  final SeatIconType iconType;

  const SeatIconRow({
    super.key,
    required this.label,
    required this.choice,
    required this.onTap,
    this.iconType = SeatIconType.empty,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            _buildPreview(),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(label, style: TextStyle(fontSize: 14.sp)),
            ),
            Icon(Icons.arrow_forward_ios, size: 14.r, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    const size = 36.0;
    if (choice == null || choice!.type == SeatIconChoiceType.defaultIcon) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade200,
        ),
        child: iconType == SeatIconType.locked
            ? const Icon(Icons.lock_rounded, size: 18, color: Colors.grey)
            : const Icon(Icons.mic_none_rounded, size: 18, color: Colors.grey),
      );
    }
    if (choice!.type == SeatIconChoiceType.preset) {
      final presetName = choice!.presetName?.replaceFirst('preset:', '') ?? '';
      const presetIcons = <String, IconData>{
        'star': Icons.star_rounded,
        'headphones': Icons.headphones_rounded,
        'music_note': Icons.music_note_rounded,
        'person': Icons.person_rounded,
        'favorite': Icons.favorite_rounded,
        'diamond': Icons.diamond_rounded,
      };
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.deepPurple.shade50,
        ),
        child: Icon(
          presetIcons[presetName] ?? Icons.mic_none_rounded,
          size: 18,
          color: Colors.deepPurple,
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: choice!.file != null
            ? DecorationImage(image: FileImage(choice!.file!), fit: BoxFit.cover)
            : null,
      ),
    );
  }
}
