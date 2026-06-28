import 'package:flutter/material.dart';

import '../shared/room_assets.dart';

class LockedSeatWidget extends StatelessWidget {
  final int index;
  final double size;

  const LockedSeatWidget({super.key, required this.index, required this.size});

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
            color: Colors.white.withValues(alpha: 0.1),
          ),
          child: Center(
            child: Image.asset(
              RoomAssets.lockSeat,
              width: iconSize * 0.5,
              height: iconSize * 0.5,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${index + 1}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
