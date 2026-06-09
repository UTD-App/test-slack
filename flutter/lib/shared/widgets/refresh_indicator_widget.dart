import 'package:flutter/material.dart';
import 'package:utd_app/shared/core/color_manager.dart';

class RefreshIndicatorWidget extends StatelessWidget {
  const RefreshIndicatorWidget({
    super.key,
    required this.onRefresh,
    required this.child,
  });
  final Future<void> Function() onRefresh;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator.adaptive(
      strokeWidth: 2.0,
      color: ColorManager.primary,
      backgroundColor: ColorManager.white,
      onRefresh: onRefresh,
      child: child,
    );
  }
}
