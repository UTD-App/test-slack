import 'package:audio_room/audio_room.dart';
import 'package:flutter/material.dart';

class PkPlugin extends AudioRoomPlugin {
  @override
  String get id => 'pk';

  @override
  String get displayName => 'PK Battle';

  @override
  Widget? buildControlsWidget(BuildContext context, int roomId) {
    return null;
  }

  @override
  Widget? buildOverlayWidget(BuildContext context, int roomId) {
    return null;
  }
}
