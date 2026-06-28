import 'package:flutter/material.dart';

import '../shared/room_assets.dart';

class ExitButton extends StatelessWidget {
  final VoidCallback onTap;

  const ExitButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red.withValues(alpha: 0.2),
        ),
        child: Image.asset(RoomAssets.exitRoom, color: Colors.red),
      ),
    );
  }
}
