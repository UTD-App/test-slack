import 'package:flutter/material.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

import 'seat_mode_sheet_body.dart';

void showSeatModeSheet(
  BuildContext context, {
  required int currentMode,
  required List<UTDRoomMode> modes,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => SeatModeSheetBody(
      currentMode: currentMode,
      modes: modes,
    ),
  );
}
