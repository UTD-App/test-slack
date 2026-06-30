import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:utd_app/localization/localization.dart';

import '../../domain/user_profile_model.dart';
import '../../profile_strings.dart';

/// Horizontal scrollable row of colorful tag chips (Agency, Tasks, VIP, …).
class ProfileBadgesRow extends StatelessWidget {
  final UserProfileModel profile;

  const ProfileBadgesRow({super.key, required this.profile});

  // Per-badge accent colors, keyed on the canonical badge id (not display
  // text); unknown badges fall back to a neutral purple.
  static const Map<String, List<Color>> _palette = {
    'agency': [Color(0xFF7C4DFF), Color(0xFF5E35B1)],
    'tasks': [Color(0xFF26C6DA), Color(0xFF00838F)],
    'vip': [Color(0xFFFFB300), Color(0xFFFF6F00)],
    'bd': [Color(0xFF66BB6A), Color(0xFF2E7D32)],
    'verified': [Color(0xFF42A5F5), Color(0xFF1565C0)],
  };

  /// Canonical id for a raw backend badge string. Maps known display variants
  /// (case-insensitive) onto stable ids used by [_palette] and the
  /// `${ProfileStrings.badgePrefix}<id>` translation keys.
  static String _canonicalId(String raw) => raw.trim().toLowerCase();

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
        itemBuilder: (context, index) => _chip(context, badges[index]),
      ),
    );
  }

  Widget _chip(BuildContext context, String raw) {
    final id = _canonicalId(raw);
    final colors =
        _palette[id] ?? const [Color(0xFFB44AFF), Color(0xFF8B2FC9)];
    // Localized label; falls back to the raw backend string when no
    // translation exists for this badge id (context.tr returns the key, so we
    // detect that and show the original text instead).
    final key = '${ProfileStrings.badgePrefix}$id';
    final translated = context.tr(key);
    final label = translated == key ? raw : translated;
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
