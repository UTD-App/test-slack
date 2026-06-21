import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:utd_app/shared/core/color_manager.dart';
import 'package:utd_app/shared/core/extensions.dart';
import 'package:utd_app/shared/widgets/image_widget.dart';
import 'package:utd_app/shared/widgets/text_widget.dart';

/// A single selectable gender card (mockup style): gradient fill + avatar when
/// selected, muted frosted card when not.
class GenderCard extends StatelessWidget {
  const GenderCard({
    super.key,
    required this.label,
    required this.iconAsset,
    required this.avatarAsset,
    required this.selected,
    required this.selectedColors,
    required this.onTap,
    this.flipIcon = false,
  });

  final String label;
  final String iconAsset;
  final String avatarAsset;
  final bool selected;
  final List<Color> selectedColors;
  final VoidCallback onTap;
  final bool flipIcon;

  @override
  Widget build(BuildContext context) {
    final icon = ImageWidget(height: 20.h, width: 20.w, image: iconAsset);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: context.paddingSymmetric(vertical: 12, horizontal: 13),
        decoration: BoxDecoration(
          borderRadius: 14.radius,
          gradient: selected ? LinearGradient(colors: selectedColors) : null,
          color: selected ? null : ColorManager.frostedFill,
          border: Border.all(
            color: selected
                ? ColorManager.transparent
                : ColorManager.frostedBorder,
          ),
        ),
        child: Row(
          children: [
            flipIcon
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.diagonal3Values(-1, 1, 1),
                    child: icon,
                  )
                : icon,
            5.wBox,
            TextWidget(
              label,
              style: context.bodyMedium.size(15).colorExt(ColorManager.white),
            ),
            const Spacer(),
            CircleAvatar(
              radius: 17.r,
              backgroundColor: ColorManager.white,
              child: Image.asset(avatarAsset, height: 30.h, width: 30.w),
            ),
          ],
        ),
      ),
    );
  }
}

/// Male/Female selector row built from two [GenderCard]s. Keeps the app's
/// label-based gender model: [selected] holds the chosen label and [onSelect]
/// reports the tapped label back to the caller.
class GenderSelector extends StatelessWidget {
  const GenderSelector({
    super.key,
    required this.maleLabel,
    required this.femaleLabel,
    required this.selected,
    required this.onSelect,
    required this.maleIcon,
    required this.maleAvatar,
    required this.femaleIcon,
    required this.femaleAvatar,
  });

  final String maleLabel;
  final String femaleLabel;
  final String selected;
  final ValueChanged<String> onSelect;
  final String maleIcon, maleAvatar, femaleIcon, femaleAvatar;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GenderCard(
            label: maleLabel,
            iconAsset: maleIcon,
            avatarAsset: maleAvatar,
            selected: selected == maleLabel,
            selectedColors: ColorManager.maleContainer,
            onTap: () => onSelect(maleLabel),
          ),
        ),
        10.wBox,
        Expanded(
          child: GenderCard(
            label: femaleLabel,
            iconAsset: femaleIcon,
            avatarAsset: femaleAvatar,
            selected: selected == femaleLabel,
            selectedColors: ColorManager.femaleContainer,
            onTap: () => onSelect(femaleLabel),
            flipIcon: true,
          ),
        ),
      ],
    );
  }
}
