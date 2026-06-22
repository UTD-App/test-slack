import 'package:flutter/material.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

import 'asset_control_button.dart';
import 'room_assets.dart';

class SpeakerButton extends StatelessWidget {
  final UTDRoomController controller;

  const SpeakerButton({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: controller.mediaController.isSpeakerOn,
      builder: (context, isOn, _) {
        return AssetControlButton(
          asset: isOn ? RoomAssets.soundOn : RoomAssets.soundOff,
          isActive: isOn,
          activeColor: Colors.blueAccent,
          onTap: () => controller.mediaController.toggleSpeaker(),
        );
      },
    );
  }
}
