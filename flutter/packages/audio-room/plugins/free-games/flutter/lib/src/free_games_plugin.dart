import 'package:audio_room/audio_room.dart';
import 'package:flutter/material.dart';

class FreeGamesPlugin extends AudioRoomPlugin {
  @override
  String get id => 'free_games';

  @override
  String get displayName => 'Free Games';

  @override
  Widget? buildControlsWidget(BuildContext context, int roomId) {
    return null;
  }

  @override
  Widget? buildOverlayWidget(BuildContext context, int roomId) {
    return null;
  }
}
