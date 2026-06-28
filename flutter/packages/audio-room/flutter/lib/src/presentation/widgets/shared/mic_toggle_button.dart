import 'package:flutter/material.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

class MicToggleButton extends StatelessWidget {
  final UTDRoomController controller;
  final VoidCallback onTap;

  const MicToggleButton({
    super.key,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: controller.mutedParticipants,
      builder: (_, muted, __) {
        final localId =
            controller.roomManager.localParticipant?.identity.toString();
        final isMuted = localId != null && muted.contains(localId);

        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isMuted
                  ? Colors.red.withValues(alpha: 0.2)
                  : Colors.green.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isMuted ? Icons.mic_off : Icons.mic,
              color: isMuted ? Colors.red : Colors.green,
              size: 16,
            ),
          ),
        );
      },
    );
  }
}
