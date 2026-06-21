import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:utd_app/addons/feature_registry.dart';
import 'package:utd_app/localization/localization.dart';
import 'package:utd_app/shared/core/color_manager.dart';
import 'package:utd_app/shared/profile/profile_view_arguments.dart';

import 'feature_grid_item.dart';
import 'profile_assets.dart';

/// 4-column grid of feature shortcuts. Every tile is package-gated via its
/// [FeatureGridItem.featureId]: it shows ONLY when the owning package is
/// installed (registered in the [FeatureRegistry]) and is hidden otherwise —
/// each reappears automatically once its package is added. Feature ids follow
/// the `com.utd.<name>` convention; the ones whose packages don't exist yet are
/// provisional and confirmed when the package is built.
class FeatureGrid extends StatelessWidget {
  const FeatureGrid({super.key});

  static const List<FeatureGridItem> _items = [
    // 'profile.level' is intentionally omitted until the level package exists —
    // it will return as a package-contributed tile, not hardcoded.
    FeatureGridItem(
        labelKey: 'profile.store',
        assetIcon: ProfileAssets.icStore,
        featureId: 'com.utd.store'),
    FeatureGridItem(
        labelKey: 'profile.tasks',
        materialIcon: Icons.checklist,
        featureId: 'com.utd.tasks'),
    FeatureGridItem(
        labelKey: 'profile.family',
        assetIcon: ProfileAssets.icFamily,
        featureId: 'com.utd.family'),
    FeatureGridItem(
        labelKey: 'profile.vip',
        materialIcon: Icons.workspace_premium,
        featureId: 'com.utd.vip'),
    FeatureGridItem(
        labelKey: 'profile.cp',
        materialIcon: Icons.favorite,
        featureId: 'com.utd.cp'),
    FeatureGridItem(
        labelKey: 'profile.bd_center',
        materialIcon: Icons.cake,
        featureId: 'com.utd.birthday'),
    FeatureGridItem(
        labelKey: 'profile.agency_center',
        materialIcon: Icons.apartment,
        featureId: 'com.utd.agency'),
    // Moment package — routed to the viewed user's posts in _resolveItems.
    FeatureGridItem(
        labelKey: 'profile.my_post',
        materialIcon: Icons.article,
        featureId: 'com.utd.moment'),
    FeatureGridItem(
        labelKey: 'profile.offline_recharge',
        assetIcon: ProfileAssets.icCoinBg,
        featureId: 'com.utd.recharge'),
    FeatureGridItem(
        labelKey: 'profile.host_center',
        materialIcon: Icons.mic_external_on,
        featureId: 'com.utd.host'),
    FeatureGridItem(
        labelKey: 'profile.my_videos',
        materialIcon: Icons.video_library,
        featureId: 'com.utd.reels'),
  ];

  /// Drops tiles whose package isn't installed and wires the ones that are.
  List<FeatureGridItem> _resolveItems(BuildContext context) {
    final registry = context.read<FeatureRegistry>();
    final args = context.read<ProfileViewArguments>();
    bool installed(String id) => registry.features.any((f) => f.id == id);

    final resolved = <FeatureGridItem>[];
    for (final item in _items) {
      if (item.featureId != null && !installed(item.featureId!)) {
        continue; // package not installed → hide the tile
      }

      // "My posts" needs the viewed user's id wired into its route. On a VISITED
      // profile this is a dedicated tab, so the shortcut tile is redundant and
      // hidden; it stays on your OWN profile (which has no tabs).
      if (item.labelKey == 'profile.my_post') {
        if (!args.isMe) continue;
        resolved.add(
          FeatureGridItem(
            labelKey: item.labelKey,
            materialIcon: Icons.article,
            featureId: item.featureId,
            route: '/moment/user/${args.userId}',
          ),
        );
        continue;
      }

      // "My videos" → same: a tab when visiting, a shortcut only on own profile.
      if (item.labelKey == 'profile.my_videos') {
        if (!args.isMe) continue;
        resolved.add(
          FeatureGridItem(
            labelKey: item.labelKey,
            materialIcon: Icons.video_library,
            featureId: item.featureId,
            route: '/reels/user/${args.userId}',
          ),
        );
        continue;
      }
      resolved.add(item);
    }

    // Settings — shown only on the user's OWN profile (a core, always-available
    // tile next to My Post / My Videos). Opens the app settings page
    // (language / theme / logout).
    if (args.isMe) {
      resolved.add(
        const FeatureGridItem(
          labelKey: 'profile.settings',
          materialIcon: Icons.settings,
          route: '/settings',
        ),
      );
    }
    return resolved;
  }

  /// Per-row icon-badge tints, cycled by index — matches the mockup's
  /// colorful frosted feature rows (Creator / Event / Wallet …).
  static const List<Color> _tints = [
    Color(0xFF8B5CF6),
    Color(0xFF26C6DA),
    Color(0xFF42A5F5),
    Color(0xFFFFB300),
    Color(0xFFEC407A),
    Color(0xFF66BB6A),
    Color(0xFF7C4DFF),
    Color(0xFFFF7043),
  ];

  @override
  Widget build(BuildContext context) {
    final items = _resolveItems(context);
    if (items.isEmpty) return const SizedBox.shrink();

    // Vertical list of frosted rounded rows (mockup profile style) instead of
    // a flat icon grid — reads as a designed list even with a single item, and
    // each package's tile slots in as another styled row when installed.
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) SizedBox(height: 10.h),
          _row(context, items[i], _tints[i % _tints.length]),
        ],
      ],
    );
  }

  Widget _row(BuildContext context, FeatureGridItem item, Color tint) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (item.route != null) {
          context.push(item.route!);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('profile.coming_soon'))),
          );
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: ColorManager.lumiaCardGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: ColorManager.frostedBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 38.w,
              height: 38.w,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(11.r),
              ),
              alignment: Alignment.center,
              child: item.assetIcon != null
                  ? Image.asset(
                      item.assetIcon!,
                      width: 20.w,
                      height: 20.w,
                      errorBuilder: (_, __, ___) =>
                          Icon(Icons.widgets, color: tint, size: 20.sp),
                    )
                  : Icon(item.materialIcon, color: tint, size: 20.sp),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                context.tr(item.labelKey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ColorManager.lumiaTextPrimary,
                  fontSize: 14.sp,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 13.sp,
              color: ColorManager.lumiaTextSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
