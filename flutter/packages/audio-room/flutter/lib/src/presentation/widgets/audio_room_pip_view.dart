import 'package:flutter/material.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

class AudioRoomPipView extends StatelessWidget {
  final dynamic room;
  final UTDRoomController controller;

  const AudioRoomPipView({
    super.key,
    required this.room,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final roomName = room?.roomName as String? ?? '';
    final roomImage = room?.roomCover as String? ?? '';

    return Scaffold(
      body: Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (roomImage.isNotEmpty)
              Image.network(
                roomImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ValueListenableBuilder<Set<String>>(
                    valueListenable: controller.activeSpeakers,
                    builder: (_, speakers, __) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: speakers.isNotEmpty
                              ? const Color(0xFF32e5ac).withValues(alpha: 0.25)
                              : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              speakers.isNotEmpty
                                  ? Icons.graphic_eq_rounded
                                  : Icons.mic_off_rounded,
                              color: speakers.isNotEmpty
                                  ? const Color(0xFF32e5ac)
                                  : Colors.white54,
                              size: 18,
                            ),
                            if (speakers.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Text(
                                '${speakers.length}',
                                style: const TextStyle(
                                  color: Color(0xFF32e5ac),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    roomName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
