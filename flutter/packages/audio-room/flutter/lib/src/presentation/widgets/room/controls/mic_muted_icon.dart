import 'package:flutter/material.dart';

import '../shared/room_assets.dart';

class MicMutedIcon extends StatelessWidget {
  final double size;

  const MicMutedIcon({super.key, required this.size});

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
        child: Image.asset(RoomAssets.micOff, color: Colors.white),
      ),
    );
  }
}
