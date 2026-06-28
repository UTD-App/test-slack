import 'package:flutter/material.dart';

class IconControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const IconControlButton({super.key, required this.icon, this.onTap});

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
