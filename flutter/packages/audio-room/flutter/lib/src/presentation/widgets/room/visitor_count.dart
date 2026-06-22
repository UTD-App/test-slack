import 'package:flutter/material.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

class VisitorCount extends StatelessWidget {
  final UTDRoomController controller;
  final VoidCallback? onTap;

  const VisitorCount({super.key, required this.controller, this.onTap});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UTDParticipant>>(
      stream: controller.participantsStream,
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? controller.participants.length;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people, color: Colors.white70, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
