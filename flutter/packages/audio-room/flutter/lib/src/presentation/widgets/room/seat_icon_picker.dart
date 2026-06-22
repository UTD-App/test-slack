import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'room_assets.dart';
import 'room_theme.dart';
import 'seat_icon_picker_sheet.dart';

enum SeatIconChoiceType { defaultIcon, preset, custom }

class SeatIconChoice {
  final SeatIconChoiceType type;
  final String? presetName;
  final File? file;

  const SeatIconChoice.defaultIcon()
      : type = SeatIconChoiceType.defaultIcon,
        presetName = null,
        file = null;

  const SeatIconChoice.preset(String name)
      : type = SeatIconChoiceType.preset,
        presetName = name,
        file = null;

  SeatIconChoice.custom(File imageFile)
      : type = SeatIconChoiceType.custom,
        presetName = null,
        file = imageFile;
}

class SeatIconPreview extends StatelessWidget {
  final String? currentValue;
  final double size;
  final SeatIconType iconType;

  const SeatIconPreview({
    super.key,
    this.currentValue,
    this.size = 40,
    this.iconType = SeatIconType.empty,
  });

  @override
  Widget build(BuildContext context) {
    if (currentValue == null) {
      return _circle(
        child: iconType == SeatIconType.locked
            ? Image.asset(
                RoomAssets.lockSeat,
                width: size * 0.5,
                height: size * 0.5,
                color: RoomTheme.textSecondary,
              )
            : Icon(Icons.mic_none_rounded, color: RoomTheme.textSecondary, size: size * 0.5),
      );
    }
    if (currentValue!.startsWith('preset:')) {
      final presetName = currentValue!.substring(7);
      return _circle(
        child: Icon(
          presetIcons[presetName] ?? Icons.mic_none_rounded,
          color: RoomTheme.textSecondary,
          size: size * 0.5,
        ),
      );
    }
    return _circle(
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: currentValue!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) =>
              Icon(Icons.image, color: RoomTheme.textSecondary, size: size * 0.5),
          errorWidget: (_, __, ___) =>
              Icon(Icons.broken_image, color: RoomTheme.textSecondary, size: size * 0.5),
        ),
      ),
    );
  }

  Widget _circle({required Widget child}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: RoomTheme.cardBg,
        border: Border.all(color: RoomTheme.textSecondary.withValues(alpha: 0.3)),
      ),
      child: Center(child: child),
    );
  }
}

const presetIcons = <String, IconData>{
  'star': Icons.star_rounded,
  'headphones': Icons.headphones_rounded,
  'music_note': Icons.music_note_rounded,
  'person': Icons.person_rounded,
  'favorite': Icons.favorite_rounded,
  'diamond': Icons.diamond_rounded,
};

enum SeatIconType { empty, locked }

Future<SeatIconChoice?> showSeatIconPicker(
  BuildContext context, {
  String? currentValue,
  SeatIconType iconType = SeatIconType.empty,
}) async {
  return showModalBottomSheet<SeatIconChoice>(
    context: context,
    backgroundColor: RoomTheme.bgDark,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
    ),
    builder: (ctx) => SeatIconPickerSheet(
      currentValue: currentValue,
      iconType: iconType,
    ),
  );
}
