import 'package:flutter/material.dart';

class AssetControlButton extends StatelessWidget {
  final String asset;
  final bool isActive;
  final Color? activeColor;
  final VoidCallback? onTap;

  const AssetControlButton({
    super.key,
    required this.asset,
    this.isActive = false,
    this.activeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive
              ? (activeColor ?? Colors.white).withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Image.asset(asset),
        ),
      ),
    );
  }
}
