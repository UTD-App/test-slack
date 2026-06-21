import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../domain/user_profile_model.dart';

/// Horizontal scrollable row of colorful tag chips (Agency, Tasks, VIP, …).
class ProfileBadgesRow extends StatelessWidget {
  final UserProfileModel profile;

  const ProfileBadgesRow({super.key, required this.profile});

  // Per-badge accent colors; unknown badges fall back to a neutral purple.
  static const Map<String, List<Color>> _palette = {
    'Agency': [Color(0xFF7C4DFF), Color(0xFF5E35B1)],
    'Tasks': [Color(0xFF26C6DA), Color(0xFF00838F)],
    'VIP': [Color(0xFFFFB300), Color(0xFFFF6F00)],
    'BD': [Color(0xFF66BB6A), Color(0xFF2E7D32)],
    'Verified': [Color(0xFF42A5F5), Color(0xFF1565C0)],
  };

  @override
  Widget build(BuildContext context) {
    final badges = profile.badges;
    if (badges.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 26.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: badges.length,
        separatorBuilder: (_, __) => SizedBox(width: 6.w),
        itemBuilder: (context, index) => _chip(badges[index]),
      ),
    );
  }

  Widget _chip(String label) {
    final colors =
        _palette[label] ?? const [Color(0xFFB44AFF), Color(0xFF8B2FC9)];
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(13.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
