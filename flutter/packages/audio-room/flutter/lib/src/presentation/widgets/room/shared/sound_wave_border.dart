import 'package:flutter/material.dart';

class SoundWaveBorder extends StatelessWidget {
  final bool isSpeaking;
  final List<AnimationController> waveControllers;
  final Size size;
  final Widget child;

  const SoundWaveBorder({
    super.key,
    required this.isSpeaking,
    required this.waveControllers,
    required this.size,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!isSpeaking) return child;

    return Stack(
      alignment: Alignment.center,
      children: [
        for (int i = 0; i < waveControllers.length; i++)
          AnimatedBuilder(
            animation: waveControllers[i],
            builder: (_, __) {
              final scale = 1.0 + (waveControllers[i].value * 0.04 * (i + 1));
              final opacity = (1.0 - waveControllers[i].value * 0.6).clamp(
                0.0,
                1.0,
              );
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: size.width,
                  height: size.height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: opacity * 0.5),
                      width: 2,
                    ),
                  ),
                ),
              );
            },
          ),
        child,
      ],
    );
  }
}
