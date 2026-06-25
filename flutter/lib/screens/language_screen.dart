import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../localization/localization.dart';
import '../shared/core/color_manager.dart';
import '../shared/widgets/gradient_background.dart';
import '../shared/widgets/gradient_card.dart';

/// Full-page language picker reached from the (server-driven) Settings screen's
/// "Language" row, which fires `core.navigate → /language-screen`. Mirrors the
/// native Settings bottom-sheet picker but as a routed page, so that Studio
/// action has a real destination instead of dead-ending on a GoRouter
/// "no routes for location: /language-screen" exception.
///
/// Lists the backend's active locales (native names from [LocaleNotifier]) and
/// switches the app language on tap; the current language shows a check, then
/// the page pops back to Settings — matching the old sheet's behaviour.
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localeNotifier = context.watch<LocaleNotifier>();
    final currentCode = localeNotifier.locale.languageCode;
    final locales = localeNotifier.supportedLocales;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: ColorManager.lumiaTextPrimary),
        title: Text(
          context.tr('app.language'),
          style: const TextStyle(
            color: ColorManager.lumiaTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
            children: [
              GradientCard(
                padding: EdgeInsets.symmetric(vertical: 4.h),
                child: Column(
                  children: [
                    for (var i = 0; i < locales.length; i++) ...[
                      if (i > 0) _divider(),
                      _languageTile(
                        context,
                        notifier: localeNotifier,
                        locale: locales[i],
                        selected: locales[i].languageCode == currentCode,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _languageTile(
    BuildContext context, {
    required LocaleNotifier notifier,
    required Locale locale,
    required bool selected,
  }) {
    // Native name from the backend's active languages (العربية, Français, …) so
    // any admin-added language shows correctly.
    final label = notifier.nameFor(locale.languageCode);
    return InkWell(
      onTap: () async {
        await notifier.setLocale(locale);
        if (context.mounted) Navigator.of(context).maybePop();
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: ColorManager.lumiaTextPrimary,
                  fontSize: 14.sp,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check, color: ColorManager.lumiaAccent),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        child: Divider(
          height: 1,
          thickness: 0.5,
          color: ColorManager.frostedBorder,
        ),
      );
}
