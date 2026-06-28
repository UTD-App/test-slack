import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:utd_app/localization/localization.dart';

import 'package:audio_room/src/audio_room_strings.dart';
import '../../data/pip_manager.dart';
import '../widgets/room/shared/room_theme.dart';
import '../widgets/room/seats/seat_icon_picker.dart';
import '../widgets/settings/file_icon_preview.dart';
import '../widgets/settings/setting_row.dart';

class SeatIconSettingsSection extends StatelessWidget {
  final String? currentEmptySeatIcon;
  final String? currentLockedSeatIcon;
  final File? emptySeatIconFile;
  final File? lockedSeatIconFile;
  final void Function({
    File? emptySeatIcon,
    File? lockedSeatIcon,
    String? emptySeatIconPreset,
    String? lockedSeatIconPreset,
  }) onSave;
  final void Function({
    File? emptySeatIconFile,
    String? emptySeatIcon,
    File? lockedSeatIconFile,
    String? lockedSeatIcon,
  }) onStateUpdate;

  const SeatIconSettingsSection({
    super.key,
    required this.currentEmptySeatIcon,
    required this.currentLockedSeatIcon,
    required this.emptySeatIconFile,
    required this.lockedSeatIconFile,
    required this.onSave,
    required this.onStateUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingRow(
          title: context.tr(AudioRoomKeys.emptySeatIcon),
          onTap: () => _handleSeatIconTap(
            context,
            currentValue: currentEmptySeatIcon,
            iconType: SeatIconType.empty,
            isEmpty: true,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              emptySeatIconFile != null
                  ? FileIconPreview(file: emptySeatIconFile!, size: 36.r)
                  : SeatIconPreview(
                      currentValue: currentEmptySeatIcon,
                      size: 36.r,
                      iconType: SeatIconType.empty,
                    ),
              SizedBox(width: 8.w),
              Icon(Icons.arrow_forward_ios,
                  color: RoomTheme.textSecondary, size: 14.r),
            ],
          ),
        ),
        const Divider(
            height: 1, indent: 16, endIndent: 16, color: RoomTheme.dividerColor),
        SettingRow(
          title: context.tr(AudioRoomKeys.lockedSeatIcon),
          onTap: () => _handleSeatIconTap(
            context,
            currentValue: currentLockedSeatIcon,
            iconType: SeatIconType.locked,
            isEmpty: false,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              lockedSeatIconFile != null
                  ? FileIconPreview(file: lockedSeatIconFile!, size: 36.r)
                  : SeatIconPreview(
                      currentValue: currentLockedSeatIcon,
                      size: 36.r,
                      iconType: SeatIconType.locked,
                    ),
              SizedBox(width: 8.w),
              Icon(Icons.arrow_forward_ios,
                  color: RoomTheme.textSecondary, size: 14.r),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleSeatIconTap(
    BuildContext context, {
    required String? currentValue,
    required SeatIconType iconType,
    required bool isEmpty,
  }) async {
    final result = await showSeatIconPicker(
      context,
      currentValue: currentValue,
      iconType: iconType,
    );
    if (result == null || !context.mounted) return;

    if (result.type == SeatIconChoiceType.pickFromGallery) {
      await PipManager.instance.disableAutoPip();
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
      );
      await PipManager.instance.enableAutoPip();
      if (image == null || !context.mounted) return;
      final file = File(image.path);
      _applyResult(file: file, presetName: null, isEmpty: isEmpty);
    } else if (result.type == SeatIconChoiceType.custom) {
      _applyResult(file: result.file, presetName: null, isEmpty: isEmpty);
    } else if (result.type == SeatIconChoiceType.preset) {
      _applyResult(file: null, presetName: result.presetName, isEmpty: isEmpty);
    } else {
      _applyResult(file: null, presetName: '', isEmpty: isEmpty);
    }
  }

  void _applyResult({
    required File? file,
    required String? presetName,
    required bool isEmpty,
  }) {
    if (isEmpty) {
      onStateUpdate(emptySeatIconFile: file, emptySeatIcon: null);
      if (presetName != null) {
        onSave(emptySeatIconPreset: presetName);
      } else if (file != null) {
        onSave(emptySeatIcon: file);
      }
    } else {
      onStateUpdate(lockedSeatIconFile: file, lockedSeatIcon: null);
      if (presetName != null) {
        onSave(lockedSeatIconPreset: presetName);
      } else if (file != null) {
        onSave(lockedSeatIcon: file);
      }
    }
  }
}
