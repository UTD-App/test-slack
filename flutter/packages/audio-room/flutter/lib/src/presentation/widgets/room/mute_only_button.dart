import 'package:flutter/material.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

import 'profile_action_button.dart';
import 'room_strings.dart';

class MuteOnlyButton extends StatelessWidget {
  final UTDRoomController controller;
  final String userId;
  final String localUserId;

  const MuteOnlyButton({
    super.key,
    required this.controller,
    required this.userId,
    required this.localUserId,
  });

  @override
  Widget build(BuildContext context) {
    final s = RoomStrings.of(context);

    return ValueListenableBuilder<Set<String>>(
      valueListenable: controller.mutedParticipants,
      builder: (context, muted, _) {
        if (muted.contains(userId)) return const SizedBox.shrink();
        return ProfileActionButton(
          icon: Icons.mic_off,
          label: s.mute,
          onTap: () async {
            final seatIndex = controller.seatController
                .getSeatIndexByUserId(userId);
            if (seatIndex < 0) return;
            final identity = controller.localIdentity ?? localUserId;
            final ok = await controller.seatController.muteSeat(
              seatIndex,
              identity: identity,
            );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(ok ? s.userMuted : s.failed)),
              );
            }
          },
        );
      },
    );
  }
}
