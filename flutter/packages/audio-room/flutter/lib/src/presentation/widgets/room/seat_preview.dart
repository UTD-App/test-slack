import 'package:flutter/material.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

import 'room_assets.dart';

class SeatPreview extends StatelessWidget {
  final UTDRoomMode mode;

  const SeatPreview({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: mode.rows.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((_) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _dot(),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _dot() {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.4),
      ),
      child: Center(
        child: Image.asset(
          RoomAssets.seat,
          width: 10,
          height: 10,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
