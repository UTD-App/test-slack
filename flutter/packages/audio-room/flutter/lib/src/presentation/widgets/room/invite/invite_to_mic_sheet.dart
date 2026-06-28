import 'package:flutter/material.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

import 'invite_to_mic_body.dart';

Future<void> showInviteToMicSheet(
  BuildContext context, {
  required UTDRoomController controller,
  required int seatIndex,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1E1E2E),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => InviteToMicBody(
      controller: controller,
      seatIndex: seatIndex,
    ),
  );
}
