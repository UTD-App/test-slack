import 'package:flutter/material.dart';

import '../core/color_manager.dart';

/// A simple loading indicator widget.
class LoadingWidget extends StatelessWidget {
  final double size;
  final Color? color;

  const LoadingWidget({super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        color: color ?? ColorManager.white,
      ),
    );
  }
}
