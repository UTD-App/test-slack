import 'package:flutter/material.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

import 'chat_button.dart';
import 'icon_control_button.dart';
import 'mic_button.dart';
import 'speaker_button.dart';

class RoomControlsBar extends StatelessWidget {
  final UTDRoomController controller;
  final VoidCallback? onModeTap;
  final bool isOwner;

  const RoomControlsBar({
    super.key,
    required this.controller,
    this.onModeTap,
    this.isOwner = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ValueListenableBuilder<List<SeatState>>(
        valueListenable: controller.seatController.seats,
        builder: (context, seats, _) {
          final isOnSeat = controller.localSeatIndex >= 0;

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isOwner && onModeTap != null) ...[
                IconControlButton(
                  icon: Icons.grid_view_rounded,
                  onTap: onModeTap,
                ),
                const SizedBox(width: 20),
              ],
              if (isOnSeat) ...[
                MicButton(controller: controller),
                const SizedBox(width: 20),
              ],
              SpeakerButton(controller: controller),
              const SizedBox(width: 20),
              ChatButton(controller: controller),
            ],
          );
        },
      ),
    );
  }
}
