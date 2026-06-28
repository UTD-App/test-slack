import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

import '../../../../audio_room_feature.dart';
import '../controls/mic_muted_icon.dart';
import 'seat_avatar_image.dart';
import 'speaking_wave.dart';

class SeatAvatarWidget extends StatelessWidget {
  final String userId;
  final double size;
  final Map<String, String> attributes;
  final bool isMuted;
  final int seatIndex;
  final String userName;
  final UTDRoomController controller;
  final int roomId;

  const SeatAvatarWidget({
    super.key,
    required this.userId,
    required this.size,
    required this.attributes,
    required this.isMuted,
    required this.seatIndex,
    required this.userName,
    required this.controller,
    this.roomId = 0,
  });

  @override
  Widget build(BuildContext context) {
    final avatarSize = size * 0.7;
    final avatarUrl = attributes['avatar'] ?? '';
    final displayName = userName.isNotEmpty
        ? userName
        : (attributes['name'] ?? '');

    return ValueListenableBuilder<Set<String>>(
      valueListenable: controller.mutedParticipants,
      builder: (context, mutedSet, _) {
        final effectivelyMuted = isMuted || mutedSet.contains(userId);

        return SizedBox(
          width: size,
          height: size,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: avatarSize,
                height: avatarSize,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    SpeakingWave(
                      userId: userId,
                      controller: controller,
                      avatarSize: avatarSize,
                    ),
                    SeatAvatarImage(url: avatarUrl, size: avatarSize),

                    ...AudioRoomFeature.registeredPlugins
                        .map((p) => p.buildSeatBadge(context, userId, roomId))
                        .where((w) => w != null)
                        .cast<Widget>(),
                    if (effectivelyMuted)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: MicMutedIcon(size: avatarSize * 0.3),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                displayName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ],
          ),
        );
      },
    );
  }
}
