import 'package:audio_room/audio_room.dart';
import 'package:flutter/material.dart';

class SuperBombPlugin extends AudioRoomPlugin {
  @override
  String get id => 'super_bomb';

  @override
  String get displayName => 'Super Bomb';

  @override
  Widget? buildControlsWidget(BuildContext context, int roomId) {
    return null;
  }

  @override
  Widget? buildOverlayWidget(BuildContext context, int roomId) {
    return null;
  }
}
