import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'room_strings.dart';

class SeatModeSelector extends StatelessWidget {
  final int selectedMode;
  final ValueChanged<int> onChanged;

  const SeatModeSelector({
    super.key,
    required this.selectedMode,
    required this.onChanged,
  });

  static const _modes = [
    (mode: 9, label: '9'),
  ];

  @override
  Widget build(BuildContext context) {
    final s = RoomStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.seatMode,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: _modes.map((m) {
            final isSelected = m.mode == selectedMode;
            return ChoiceChip(
              label: Text(s.seats(m.label)),
              selected: isSelected,
              onSelected: (_) => onChanged(m.mode),
            );
          }).toList(),
        ),
      ],
    );
  }
}
