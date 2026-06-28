import 'package:flutter/material.dart';

class SeatOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const SeatOptionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: Colors.white.withValues(alpha: 0.06),
        leading: Icon(icon, color: Colors.white, size: 22),
        title:
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 15)),
        onTap: onTap,
      ),
    );
  }
}
