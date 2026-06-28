import 'package:flutter/material.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

import 'asset_control_button.dart';
import '../shared/room_assets.dart';

class MicButton extends StatelessWidget {
  final UTDRoomController controller;

  const MicButton({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: controller.mediaController.isMicEnabled,
      builder: (context, isOn, _) {
        return AssetControlButton(
          asset: isOn ? RoomAssets.micOn : RoomAssets.micOff,
          isActive: isOn,
          activeColor: const Color(0xFF4CAF50),
          onTap: () => controller.mediaController.toggleMicrophone(),
        );
      },
    );
  }
}
