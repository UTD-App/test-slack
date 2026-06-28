import 'package:flutter/material.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

import 'package:utd_app/localization/localization.dart';

import '../../../../audio_room_strings.dart';
import 'mode_card.dart';

class SeatModeSheetBody extends StatelessWidget {
  final int currentMode;
  final List<UTDRoomMode> modes;
  final ValueChanged<int>? onModeSelected;

  const SeatModeSheetBody({
    super.key,
    required this.currentMode,
    required this.modes,
    this.onModeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height / 1.8,
        child: Column(
          children: [
            Container(
              height: 46,
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Center(
                child: Text(
                  context.tr(AudioRoomKeys.changeSeatMode),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: modes.map((mode) {
                    final modeId = int.tryParse(mode.id) ?? 0;
                    final isSelected = modeId == currentMode;
                    return ModeCard(
                      mode: mode,
                      isSelected: isSelected,
                      onTap: isSelected
                          ? null
                          : () => onModeSelected?.call(modeId),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
