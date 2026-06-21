import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:utd_app/shared/core/color_manager.dart';
import 'package:utd_app/shared/core/extensions.dart';
import 'package:utd_app/shared/widgets/button_widget.dart';
import 'package:utd_app/shared/widgets/text_widget.dart';

/// A styled vertical number wheel (e.g. age). The centered value is large/bold
/// white; neighbours fade out behind a faint highlight band — mirrors the
/// "Your age" picker in the mockup.
class NumberWheelPicker extends StatefulWidget {
  const NumberWheelPicker({
    super.key,
    required this.min,
    required this.max,
    required this.initial,
    this.onChanged,
    this.itemExtent = 56,
    this.height = 220,
  });

  final int min;
  final int max;
  final int initial;
  final ValueChanged<int>? onChanged;
  final double itemExtent;
  final double height;

  @override
  State<NumberWheelPicker> createState() => _NumberWheelPickerState();
}

class _NumberWheelPickerState extends State<NumberWheelPicker> {
  late final FixedExtentScrollController _controller;
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial.clamp(widget.min, widget.max);
    _controller = FixedExtentScrollController(
      initialItem: _selected - widget.min,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.max - widget.min + 1;
    return SizedBox(
      height: widget.height.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Highlight band behind the centered value.
          Container(
            height: widget.itemExtent.h,
            margin: context.paddingSymmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: ColorManager.frostedFill,
              borderRadius: 16.radius,
            ),
          ),
          ListWheelScrollView.useDelegate(
            controller: _controller,
            itemExtent: widget.itemExtent.h,
            perspective: 0.003,
            diameterRatio: 1.6,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (i) {
              setState(() => _selected = widget.min + i);
              widget.onChanged?.call(_selected);
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: count,
              builder: (context, i) {
                final value = widget.min + i;
                final isSelected = value == _selected;
                return Center(
                  child: TextWidget(
                    '$value',
                    style: context.bodyLarge
                        .size(isSelected ? 30 : 20)
                        .colorExt(
                          isSelected
                              ? ColorManager.white
                              : ColorManager.lumiaTextSecondary
                                  .withValues(alpha: 0.5),
                        )
                        .copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows the "Your age" bottom sheet from the mockup and returns the picked age
/// (or null if dismissed): title + wheel + full-width pink "Done" button on the
/// brighter onboarding gradient.
Future<int?> showAgePickerSheet(
  BuildContext context, {
  required String title,
  required String doneLabel,
  int initial = 18,
  int min = 18,
  int max = 80,
}) {
  int picked = initial.clamp(min, max);
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      return Container(
        padding: sheetContext.paddingOnly(
          top: 24,
          bottom: 28,
          start: 20,
          end: 20,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: ColorManager.authBgGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.vertical(top: 28.radiusCircular),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextWidget(
              title,
              style: sheetContext.bodyLarge.w600
                  .size(18)
                  .colorExt(ColorManager.white),
            ),
            20.hBox,
            NumberWheelPicker(
              min: min,
              max: max,
              initial: picked,
              onChanged: (v) => picked = v,
            ),
            24.hBox,
            ButtonWidget(
              title: doneLabel,
              height: 54,
              radius: 30,
              backgroundColors: ColorManager.pinkCtaGradient,
              onPressed: () => Navigator.of(sheetContext).pop(picked),
            ),
          ],
        ),
      );
    },
  );
}
