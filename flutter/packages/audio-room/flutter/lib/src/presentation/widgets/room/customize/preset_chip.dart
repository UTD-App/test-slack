import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../shared/room_theme.dart';

class PresetChip extends StatelessWidget {
  final IconData icon;
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const PresetChip({
    super.key,
    required this.icon,
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56.r,
        height: 56.r,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? RoomTheme.accent.withValues(alpha: 0.2) : RoomTheme.cardBg,
          border: Border.all(
            color: isSelected ? RoomTheme.accent : RoomTheme.textSecondary.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Icon(
          icon,
          color: isSelected ? RoomTheme.accent : RoomTheme.textSecondary,
          size: 26.r,
        ),
      ),
    );
  }
}
