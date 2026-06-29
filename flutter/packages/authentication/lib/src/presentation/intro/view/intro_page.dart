import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:utd_app/addons/addons.dart';
import 'package:utd_app/localization/localization_extensions.dart';
import 'package:utd_app/shared/core/shared.dart';
import 'package:utd_app/shared/widgets/ui_slot_renderer.dart';
import 'package:authentication/core/asset_manager.dart';
import '../../../../core/auth_routes.dart';
import '../../../../core/auth_strings.dart';

/// Auth landing page: a clean purple-pink hero (logo + tagline), a frosted card
/// with a pink "Create Account" primary CTA and a ghost "Sign in with Email"
/// secondary, an inline EN|ع language toggle, and the Terms/Privacy footer.
class IntroPage extends StatefulWidget {
  final String? error;
  const IntroPage({super.key, this.error});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  @override
  void initState() {
    super.initState();
    final err = widget.error;
    if (err != null && err.isNotEmpty) {
      // Surface a ban/error reason passed in via the route (e.g. blocked login).
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.tr(AuthStrings.ban)),
            content: Text(err),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: Text(context.tr(AuthStrings.ok)),
              ),
            ],
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        colors: ColorManager.authBgGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        child: Stack(
          children: [
            // Soft, on-brand glow blobs for depth (replaces the old emoji clutter).
            Positioned(
              top: -60.h,
              left: -50.w,
              child: _glow(
                ColorManager.lumiaAccent.withValues(alpha: 0.32),
                240,
              ),
            ),
            Positioned(
              bottom: 30.h,
              right: -70.w,
              child: _glow(
                ColorManager.pinkCtaGradient.first.withValues(alpha: 0.26),
                300,
              ),
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  children: [
                    8.hBox,
                    const Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: LanguageTogglePill(),
                    ),
                    const Spacer(flex: 2),
                    _hero(context),
                    const Spacer(flex: 2),
                    _card(context),
                    const Spacer(flex: 3),
                    _footer(context),
                    16.hBox,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A blurred radial glow (transparent circle whose soft shadow is the glow).
  Widget _glow(Color color, double diameter) {
    return Container(
      width: diameter.w,
      height: diameter.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color, blurRadius: 120, spreadRadius: 50),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogoBadge(
          size: 118,
          fallback: Image.asset(AssetManager.logo, fit: BoxFit.contain),
        ),
        16.hBox,
        TextWidget(
          context.tr(AuthStrings.playStreamConnect),
          style: context.bodyMedium.w500
              .size(15)
              .colorExt(ColorManager.white.withValues(alpha: 0.92)),
        ),
      ],
    );
  }

  Widget _card(BuildContext context) {
    return GradientCard(
      frosted: true,
      radius: 28,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _authButton(
            context,
            label: context.tr(AuthStrings.createAccount),
            onTap: () => context.push(AuthRoutes.register),
            primary: true,
          ),
          14.hBox,
          _authButton(
            context,
            label: context.tr(AuthStrings.signInWithEmail),
            onTap: () => context.push(AuthRoutes.login),
            primary: false,
          ),
          // Optional third-party login methods contributed by feature packages
          // (empty when none are installed — renders nothing).
          UiSlotRenderer(
            slot: UiSlot.loginMethods,
            featureRegistry: context.read<FeatureRegistry>(),
            padding: const EdgeInsets.only(top: 12),
            spacing: 12,
          ),
        ],
      ),
    );
  }

  Widget _authButton(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
    required bool primary,
  }) {
    return ButtonWidget(
      onPressed: onTap,
      width: double.infinity,
      height: 55.h,
      radius: 30.r,
      elevation: 0,
      shadowColor: ColorManager.transparent,
      padding: EdgeInsets.zero,
      paddingButton: EdgeInsets.zero,
      backgroundColors: primary ? ColorManager.pinkCtaGradient : null,
      backgroundColor: primary ? null : ColorManager.transparent,
      borderColor: primary
          ? ColorManager.transparent
          : ColorManager.white.withValues(alpha: 0.55),
      borderWidth: primary ? 0 : 1.4,
      title: TextWidget(
        label,
        style: context.bodyMedium.w700.size(16).colorExt(ColorManager.white),
      ),
    );
  }

  Widget _footer(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AuthRoutes.privacy),
      child: Text.rich(
        textAlign: TextAlign.center,
        TextSpan(
          children: [
            TextSpan(text: context.tr(AuthStrings.bySigningUp)),
            TextSpan(
              text: context.tr(AuthStrings.termsOfService),
              style: const TextStyle(
                decoration: TextDecoration.underline,
                decorationColor: ColorManager.white,
              ),
            ),
            const TextSpan(text: ' • '),
            TextSpan(
              text: context.tr(AuthStrings.privacyPolicy),
              style: const TextStyle(
                decoration: TextDecoration.underline,
                decorationColor: ColorManager.white,
              ),
            ),
          ],
        ),
        style: context.bodyMedium
            .size(13)
            .colorExt(ColorManager.white.withValues(alpha: 0.75)),
      ),
    );
  }
}
