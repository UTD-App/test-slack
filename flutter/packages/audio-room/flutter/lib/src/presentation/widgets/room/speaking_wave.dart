import 'package:flutter/material.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

class SpeakingWave extends StatefulWidget {
  final String userId;
  final UTDRoomController controller;
  final double avatarSize;

  const SpeakingWave({
    super.key,
    required this.userId,
    required this.controller,
    required this.avatarSize,
  });

  @override
  State<SpeakingWave> createState() => _SpeakingWaveState();
}

class _SpeakingWaveState extends State<SpeakingWave>
    with TickerProviderStateMixin {
  late final AnimationController _wave1;
  late final AnimationController _wave2;

  @override
  void initState() {
    super.initState();
    _wave1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _wave2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _wave1.dispose();
    _wave2.dispose();
    super.dispose();
  }

  void _onSpeakingChanged(bool isSpeaking) {
    if (isSpeaking) {
      _wave1.repeat();
      _wave2.repeat();
    } else {
      _wave1.stop();
      _wave2.stop();
      _wave1.value = 0;
      _wave2.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: widget.controller.activeSpeakers,
      builder: (context, speakers, _) {
        final isSpeaking = speakers.contains(widget.userId);
        _onSpeakingChanged(isSpeaking);

        if (!isSpeaking) {
          return SizedBox(width: widget.avatarSize, height: widget.avatarSize);
        }

        return SizedBox(
          width: widget.avatarSize + 16,
          height: widget.avatarSize + 16,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _wave2,
                builder: (_, __) {
                  final scale = 1.0 + (_wave2.value * 0.15);
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: widget.avatarSize + 10,
                      height: widget.avatarSize + 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(
                            0xFF4CAF50,
                          ).withValues(alpha: 0.3 - (_wave2.value * 0.2)),
                          width: 3,
                        ),
                      ),
                    ),
                  );
                },
              ),
              AnimatedBuilder(
                animation: _wave1,
                builder: (_, __) {
                  final scale = 1.0 + (_wave1.value * 0.08);
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: widget.avatarSize + 4,
                      height: widget.avatarSize + 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF4CAF50),
                          width: 2.5,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
