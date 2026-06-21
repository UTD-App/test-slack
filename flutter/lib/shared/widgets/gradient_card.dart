import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:utd_app/config/app_theme.dart';
import 'package:utd_app/shared/core/color_manager.dart';

/// Rounded, frosted gradient card matching the mockup's surface style:
/// soft inner gradient fill, subtle light border, generous corner radius.
class GradientCard extends StatelessWidget {
  const GradientCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.radius = 20,
    this.colors,
    this.borderColor,
    this.onTap,
    this.width,
    this.height,
    this.frosted = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final List<Color>? colors;
  final Color? borderColor;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  /// Use a translucent light fill instead of the dark card gradient — for cards
  /// placed over the brighter onboarding/auth backgrounds (mockup style).
  final bool frosted;

  @override
  Widget build(BuildContext context) {
    // Non-frosted cards use the admin card palette (defaults to the built-in
    // lumia card colors); frosted cards keep their translucent light fill.
    final palette = AppThemeProvider.current;
    final fill = colors ??
        (frosted
            ? const [ColorManager.frostedFill, ColorManager.frostedFill]
            : [palette.cardBg, palette.cardBorder]);
    final card = Container(
      width: width,
      height: height,
      padding: padding ?? EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: fill,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius.r),
        border: Border.all(
          color: borderColor ?? ColorManager.frostedBorder,
          width: 1,
        ),
      ),
      child: child,
    );

    final padded = Padding(
      padding: margin ?? EdgeInsets.zero,
      child: card,
    );

    if (onTap == null) return padded;

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius.r),
          onTap: onTap,
          child: card,
        ),
      ),
    );
  }
}
