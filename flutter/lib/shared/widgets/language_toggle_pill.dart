import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../localization/locale_notifier.dart';
import '../core/color_manager.dart';

/// A small frosted `EN | ع` pill that switches the app locale in one tap.
///
/// Reads/sets the shared [LocaleNotifier], which persists the choice, syncs the
/// backend `X-localization` header, and rebuilds the whole app (flipping to RTL
/// for Arabic via the MaterialApp locale). Stateless and self-contained, so it
/// can be dropped on any screen (intro, settings, …).
class LanguageTogglePill extends StatelessWidget {
  const LanguageTogglePill({super.key});

  @override
  Widget build(BuildContext context) {
    final current = context.watch<LocaleNotifier>().locale.languageCode;

    return Container(
      padding: EdgeInsets.all(3.r),
      decoration: BoxDecoration(
        color: ColorManager.frostedFill,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: ColorManager.frostedBorder, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment(context, label: 'EN', code: 'en', active: current == 'en'),
          _segment(context, label: 'ع', code: 'ar', active: current == 'ar'),
        ],
      ),
    );
  }

  Widget _segment(
    BuildContext context, {
    required String label,
    required String code,
    required bool active,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: active
          ? null
          : () => context.read<LocaleNotifier>().setLocale(Locale(code)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: active ? ColorManager.white : Colors.transparent,
          borderRadius: BorderRadius.circular(30.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: active
                ? ColorManager.lumiaBgDark
                : ColorManager.white.withValues(alpha: 0.75),
          ),
        ),
      ),
    );
  }
}
