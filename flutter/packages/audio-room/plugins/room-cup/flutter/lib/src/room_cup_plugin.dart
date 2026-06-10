import 'package:audio_room/audio_room.dart';
import 'package:flutter/material.dart';

class RoomCupPlugin extends AudioRoomPlugin {
  @override
  String get id => 'room-cup';

  @override
  String get displayName => 'Room Cup';

  @override
  Widget? buildControlsWidget(BuildContext context, int roomId) {
    return null;
  }

  @override
  Widget? buildOverlayWidget(BuildContext context, int roomId) {
    return null;
  }
}
