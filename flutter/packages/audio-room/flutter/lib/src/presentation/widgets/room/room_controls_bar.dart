import 'package:flutter/material.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

import 'room_assets.dart';

class RoomControlsBar extends StatelessWidget {
  final UTDRoomController controller;
  final VoidCallback? onMessageTap;
  final VoidCallback? onModeTap;
  final bool isOwner;

  const RoomControlsBar({
    super.key,
    required this.controller,
    this.onMessageTap,
    this.onModeTap,
    this.isOwner = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ValueListenableBuilder<List<SeatState>>(
        valueListenable: controller.seatController.seats,
        builder: (context, seats, _) {
          final isOnSeat = controller.localSeatIndex >= 0;

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isOwner && onModeTap != null) ...[
                _IconControlButton(
                  icon: Icons.grid_view_rounded,
                  onTap: onModeTap,
                ),
                const SizedBox(width: 20),
              ],
              if (isOnSeat) ...[
                _MicButton(controller: controller),
                const SizedBox(width: 20),
              ],
              _SpeakerButton(controller: controller),
            ],
          );
        },
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  final UTDRoomController controller;

  const _MicButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: controller.mediaController.isMicEnabled,
      builder: (context, isOn, _) {
        return _AssetControlButton(
          asset: isOn ? RoomAssets.micOn : RoomAssets.micOff,
          isActive: isOn,
          activeColor: const Color(0xFF4CAF50),
          onTap: () => controller.mediaController.toggleMicrophone(),
        );
      },
    );
  }
}

class _SpeakerButton extends StatelessWidget {
  final UTDRoomController controller;

  const _SpeakerButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: controller.mediaController.isSpeakerOn,
      builder: (context, isOn, _) {
        return _AssetControlButton(
          asset: isOn ? RoomAssets.soundOn : RoomAssets.soundOff,
          isActive: isOn,
          activeColor: Colors.blueAccent,
          onTap: () => controller.mediaController.toggleSpeaker(),
        );
      },
    );
  }
}

class _IconControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _IconControlButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.12),
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
    );
  }
}

class _AssetControlButton extends StatelessWidget {
  final String asset;
  final bool isActive;
  final Color? activeColor;
  final VoidCallback? onTap;

  const _AssetControlButton({
    required this.asset,
    this.isActive = false,
    this.activeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive
              ? (activeColor ?? Colors.white).withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Image.asset(asset),
        ),
      ),
    );
  }
}
