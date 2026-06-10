import 'package:audio_room/audio_room.dart';
import 'package:flutter/material.dart';

class CharismaPlugin extends AudioRoomPlugin {
  @override
  String get id => 'charisma';

  @override
  String get displayName => 'Charisma';

  @override
  Widget? buildControlsWidget(BuildContext context, int roomId) {
    return null;
  }

  @override
  Widget? buildOverlayWidget(BuildContext context, int roomId) {
    return null;
  }
}
