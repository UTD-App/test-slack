import 'package:flutter/material.dart';

class EmptySeatWidget extends StatelessWidget {
  final int index;
  final double size;

  const EmptySeatWidget({super.key, required this.index, required this.size});

  @override
  Widget build(BuildContext context) {
    final iconSize = size * 0.7;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Icon(
            Icons.mic_none_rounded,
            color: Colors.white.withValues(alpha: 0.5),
            size: iconSize * 0.45,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${index + 1}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
