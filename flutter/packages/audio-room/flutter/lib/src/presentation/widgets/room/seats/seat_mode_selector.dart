import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:utd_app/localization/localization.dart';

import '../../../../audio_room_feature.dart';
import '../../../../audio_room_strings.dart';

class SeatModeSelector extends StatelessWidget {
  final int selectedMode;
  final ValueChanged<int> onChanged;

  const SeatModeSelector({
    super.key,
    required this.selectedMode,
    required this.onChanged,
  });

  static List<({int mode, String label})> _buildModes() {
    return [
      (mode: 9, label: '9'),
      ...AudioRoomFeature.instance?.modePlugins.map(
            (p) => (
              mode: int.tryParse(p.backendCode) ?? 0,
              label: p.seatCount.toString(),
            ),
          ) ??
          const [],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final modes = _buildModes();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr(AudioRoomKeys.seatMode),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: modes.map((m) {
            final isSelected = m.mode == selectedMode;
            return ChoiceChip(
              label: Text(context.trArgs(AudioRoomKeys.seats, {'count': m.label})),
              selected: isSelected,
              onSelected: (_) => onChanged(m.mode),
            );
          }).toList(),
        ),
      ],
    );
  }
}
