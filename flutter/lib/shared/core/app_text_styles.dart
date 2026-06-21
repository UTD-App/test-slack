import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'color_manager.dart';

/// Semantic text styles for the app's design system.
///
/// Complements — does NOT replace — the chained extensions in `extensions.dart`
/// (`context.bodyMedium.size(16).w600`). Use these named styles for consistent
/// typography across packages; reach for the extensions for one-off tweaks.
///
/// Sizes are ScreenUtil-scaled (`.sp`), so these are getters (not `const`):
/// they resolve against the active screen at call time.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get h1 => TextStyle(
        fontSize: 28.sp,
        fontWeight: FontWeight.w700,
        color: ColorManager.lumiaTextPrimary,
      );

  static TextStyle get h2 => TextStyle(
        fontSize: 22.sp,
        fontWeight: FontWeight.w700,
        color: ColorManager.lumiaTextPrimary,
      );

  static TextStyle get h3 => TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        color: ColorManager.lumiaTextPrimary,
      );

  static TextStyle get title => TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        color: ColorManager.lumiaTextPrimary,
      );

  static TextStyle get body => TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        color: ColorManager.lumiaTextPrimary,
      );

  static TextStyle get bodySecondary => TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        color: ColorManager.lumiaTextSecondary,
      );

  static TextStyle get caption => TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        color: ColorManager.lumiaTextSecondary,
      );

  static TextStyle get button => TextStyle(
        fontSize: 15.sp,
        fontWeight: FontWeight.w600,
        color: ColorManager.white,
      );

  static TextStyle get label => TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w500,
        color: ColorManager.lumiaTextSecondary,
      );
}
