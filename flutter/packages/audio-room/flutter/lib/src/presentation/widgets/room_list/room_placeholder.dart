import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RoomPlaceholder extends StatelessWidget {
  const RoomPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey.shade300, Colors.grey.shade400],
        ),
      ),
      child: Center(
        child: Icon(Icons.mic_rounded, size: 36.r, color: Colors.white54),
      ),
    );
  }
}
