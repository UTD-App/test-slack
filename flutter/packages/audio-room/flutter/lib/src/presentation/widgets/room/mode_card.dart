import 'package:flutter/material.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

import 'room_strings.dart';
import 'seat_preview.dart';

class ModeCard extends StatelessWidget {
  final UTDRoomMode mode;
  final bool isSelected;

  const ModeCard({
    super.key,
    required this.mode,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidth = (MediaQuery.of(context).size.width - 24 - 32 - 24) / 2;
    final s = RoomStrings.of(context);

    return Container(
      width: cardWidth,
      height: cardWidth * 1.2,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isSelected
            ? const Color(0xFF32e5ac).withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.06),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF32e5ac)
              : Colors.white.withValues(alpha: 0.15),
          width: isSelected ? 1.5 : 0.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: SeatPreview(mode: mode),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              s.seats(mode.seatCount.toString()),
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.6),
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
