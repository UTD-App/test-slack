import 'package:flutter/material.dart';

class DurationTile extends StatelessWidget {
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const DurationTile({
    super.key,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: Text(
        label,
        style: TextStyle(color: color ?? Colors.white, fontSize: 15),
      ),
      onTap: onTap,
    );
  }
}
