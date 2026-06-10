import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

import 'room_assets.dart';

class SeatAvatarWidget extends StatelessWidget {
  final String userId;
  final double size;
  final Map<String, String> attributes;
  final bool isMuted;
  final int seatIndex;
  final String userName;
  final UTDRoomController controller;

  const SeatAvatarWidget({
    super.key,
    required this.userId,
    required this.size,
    required this.attributes,
    required this.isMuted,
    required this.seatIndex,
    required this.userName,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final avatarSize = size * 0.7;
    final avatarUrl = attributes['avatar'] ?? '';
    final displayName = userName.isNotEmpty
        ? userName
        : (attributes['name'] ?? '');

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
              alignment: Alignment.center,
              children: [
                _SpeakingGlow(
                  userId: userId,
                  controller: controller,
                  avatarSize: avatarSize,
                ),
                _Avatar(url: avatarUrl, size: avatarSize),
                if (isMuted)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: _MicMutedIcon(size: avatarSize * 0.3),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            displayName,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeakingGlow extends StatelessWidget {
  final String userId;
  final UTDRoomController controller;
  final double avatarSize;

  const _SpeakingGlow({
    required this.userId,
    required this.controller,
    required this.avatarSize,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: controller.activeSpeakers,
      builder: (context, speakers, _) {
        final isSpeaking = speakers.contains(userId);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isSpeaking ? avatarSize + 8 : avatarSize,
          height: isSpeaking ? avatarSize + 8 : avatarSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: isSpeaking
                ? Border.all(color: const Color(0xFF4CAF50), width: 3)
                : null,
          ),
        );
      },
    );
  }
}

class _Avatar extends StatelessWidget {
  final String url;
  final double size;

  const _Avatar({required this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade700,
        ),
        child: Icon(
          Icons.person,
          color: Colors.white.withValues(alpha: 0.7),
          size: size * 0.5,
        ),
      );
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade700,
          ),
          child: Icon(
            Icons.person,
            color: Colors.white.withValues(alpha: 0.7),
            size: size * 0.5,
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade700,
          ),
          child: Icon(
            Icons.person,
            color: Colors.white.withValues(alpha: 0.7),
            size: size * 0.5,
          ),
        ),
      ),
    );
  }
}

class _MicMutedIcon extends StatelessWidget {
  final double size;

  const _MicMutedIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.red,
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.15),
        child: Image.asset(
          RoomAssets.micOff,
          color: Colors.white,
        ),
      ),
    );
  }
}
