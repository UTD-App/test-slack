import 'package:flutter/material.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

import 'plugin_setting_row.dart';

abstract class AudioRoomPlugin {
  String get id;
  String get displayName;

  Widget? buildControlsWidget(BuildContext context, int roomId);

  Widget? buildOverlayWidget(BuildContext context, int roomId);

  Widget? buildSeatBadge(BuildContext context, String userId, int roomId) =>
      null;

  List<PluginSettingRow> getSettingRows(BuildContext context, int roomId) =>
      const [];

  List<String> get conflictsWith => const [];

  List<String> get rtmMessageTypes => const [];

  void onRtmMessage(String type, Map<String, dynamic> data) {}

  void onRoomEnter(int roomId, String userId) {}

  void onRoomExit(int roomId, String userId) {}

  void onControllerReady(UTDRoomController controller) {}
}
