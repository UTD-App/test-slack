import 'package:flutter/material.dart';

abstract class AudioRoomPlugin {
  String get id;
  String get displayName;

  Widget? buildControlsWidget(BuildContext context, int roomId);

  Widget? buildOverlayWidget(BuildContext context, int roomId);
}
