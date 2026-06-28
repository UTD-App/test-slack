import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:utd_app/localization/localization.dart';

import '../../../../audio_room_strings.dart';
import '../shared/default_option_tile.dart';
import '../customize/preset_chip.dart';
import '../shared/room_assets.dart';
import '../shared/room_theme.dart';
import 'seat_icon_picker.dart';

class SeatIconPickerSheet extends StatelessWidget {
  final String? currentValue;
  final SeatIconType iconType;

  const SeatIconPickerSheet({
    super.key,
    this.currentValue,
    this.iconType = SeatIconType.empty,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: RoomTheme.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              context.tr(AudioRoomKeys.chooseSeatIcon),
              style: TextStyle(
                color: RoomTheme.textPrimary,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            DefaultOptionTile(
              label: context.tr(AudioRoomKeys.defaultIcon),
              assetPath: iconType == SeatIconType.locked
                  ? RoomAssets.lockSeat
                  : RoomAssets.seat,
              isSelected: currentValue == null,
              onTap: () => Navigator.pop(context, const SeatIconChoice.defaultIcon()),
            ),
            SizedBox(height: 12.h),
            Text(
              context.tr(AudioRoomKeys.presets),
              style: TextStyle(color: RoomTheme.textSecondary, fontSize: 13.sp),
            ),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 12.w,
              runSpacing: 12.h,
              children: presetIcons.entries.map((e) {
                final isSelected = currentValue == 'preset:${e.key}';
                return PresetChip(
                  icon: e.value,
                  name: e.key,
                  isSelected: isSelected,
                  onTap: () => Navigator.pop(context, SeatIconChoice.preset('preset:${e.key}')),
                );
              }).toList(),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context, const SeatIconChoice.pickFromGallery());
                },
                icon: const Icon(Icons.upload_rounded, color: RoomTheme.accent),
                label: Text(context.tr(AudioRoomKeys.uploadIcon), style: const TextStyle(color: RoomTheme.accent)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: RoomTheme.accent),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }
}
