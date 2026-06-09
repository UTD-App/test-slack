import 'dart:math' as math;

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

class IntroPage extends StatefulWidget {
  final String? error;
  const IntroPage({super.key, this.error});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> with TickerProviderStateMixin {
  late final AnimationController _mainCtrl;
  final ValueNotifier<Offset> _parallaxOffset = ValueNotifier(Offset.zero);

  @override
  void initState() {
    super.initState();

    _mainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    if (widget.error != null && (widget.error ?? '').isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.tr(AuthStrings.ban)),
            content: Text(widget.error ?? ''),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _parallaxOffset.dispose();
    super.dispose();
  }

  void _onPointerMove(PointerEvent e, Size size) {
    final nx = ((e.position.dx / size.width) - 0.5).clamp(-0.5, 0.5);
    final ny = ((e.position.dy / size.height) - 0.5).clamp(-0.5, 0.5);
    _parallaxOffset.value = Offset(nx * 18, ny * 18);
  }

  Widget _emojiWidget({
    required String emoji,
    required double fontSize,
    required double offset,
    required double delay,
  }) {
    return AnimatedBuilder(
      animation: _mainCtrl,
      builder: (context, child) {
        final t =
            (math.sin((_mainCtrl.value * math.pi * 2) + delay) * 0.5) + 0.5;
        final dy = offset * t;
        final scale =
            1 + 0.04 * math.sin((_mainCtrl.value * math.pi * 2) + delay);
        return Transform.translate(
          offset: Offset(0, -dy),
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: Text(
        emoji,
        style: context.bodyMedium.copyWith(
          fontSize: fontSize,
          height: 1,
          color: Colors.white.withValues(alpha: 0.95),
          shadows: const [
            Shadow(blurRadius: 6, color: Colors.black26, offset: Offset(0, 3)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = ColorManager.primary;
    final hsl = HSLColor.fromColor(baseColor);

    final gradient = LinearGradient(
      begin: AlignmentDirectional.topStart,
      end: AlignmentDirectional.bottomEnd,
      colors: [
        hsl.withLightness((hsl.lightness + 0.05).clamp(0.0, 1.0)).toColor(),
        hsl.withLightness((hsl.lightness - 0.25).clamp(0.0, 1.0)).toColor(),
        hsl.withLightness((hsl.lightness - 0.35).clamp(0.0, 1.0)).toColor(),
      ],
      stops: const [0.0, 0.6, 1.0],
    );

    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: Listener(
          onPointerHover: (e) => _onPointerMove(e, size),
          onPointerMove: (e) => _onPointerMove(e, size),
          child: Stack(
            children: [
              ValueListenableBuilder<Offset>(
                valueListenable: _parallaxOffset,
                builder: (context, offset, child) {
                  return Transform.translate(offset: offset, child: child);
                },
                child: Opacity(
                  opacity: 0.45,
                  child: Stack(
                    children: [
                      Positioned(
                        left: size.width * 0.040,
                        top: size.height * 0.080,
                        child: _emojiWidget(
                          emoji: '🎮',
                          fontSize: 70.h,
                          offset: 25,
                          delay: 0,
                        ),
                      ),
                      Positioned(
                        left: size.width * 0.080,
                        top: size.height * 0.25,
                        child: _emojiWidget(
                          emoji: '😎',
                          fontSize: 45.h,
                          offset: 20,
                          delay: 1.2,
                        ),
                      ),
                      Positioned(
                        right: size.width * 0.080,
                        top: size.height * 0.10,
                        child: _emojiWidget(
                          emoji: '📹',
                          fontSize: 50.h,
                          offset: 18,
                          delay: 2.4,
                        ),
                      ),
                      Positioned(
                        right: size.width * 0.10,
                        top: size.height * 0.45,
                        child: _emojiWidget(
                          emoji: '💬',
                          fontSize: 50.h,
                          offset: 20,
                          delay: 0.9,
                        ),
                      ),
                      Positioned(
                        right: size.width * 0.22,
                        bottom: size.height * 0.25,
                        child: _emojiWidget(
                          emoji: '🏆',
                          fontSize: 60.h,
                          offset: 28,
                          delay: 1.8,
                        ),
                      ),
                      Positioned(
                        left: size.width * 0.070,
                        bottom: size.height * 0.180,
                        child: _emojiWidget(
                          emoji: '▶️',
                          fontSize: 50.h,
                          offset: 20,
                          delay: 0.9,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: SafeArea(
                  child: Center(
                    child: Column(
                      children: [
                        (size.width / 2.75).hBox,
                        Column(
                          children: [
                            Image.asset(
                              AssetManager.logo,
                              height: 120.h,
                              width: 120.w,
                            ),
                            5.hBox,
                            TextWidget(
                              context.tr(AuthStrings.playStreamConnect),
                              style: context.bodyMedium.w400
                                  .size(14)
                                  .colorExt(
                                    ColorManager.white.withValues(alpha: 0.95),
                                  ),
                            ),
                          ],
                        ),
                        40.hBox,
                        Container(
                          padding: context.paddingOnly(
                            start: 20,
                            end: 20,
                            bottom: 20,
                            top: 50,
                          ),
                          margin: context.paddingSymmetric(horizontal: 17.5),
                          decoration: BoxDecoration(
                            color: ColorManager.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: ColorManager.white.withValues(
                                alpha: 0.120,
                              ),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: ColorManager.white.withValues(
                                  alpha: 0.03,
                                ),
                                blurRadius: 18,
                                spreadRadius: 8,
                                offset: const Offset(0, -6),
                              ),
                              BoxShadow(
                                color: ColorManager.black.withValues(
                                  alpha: 0.120,
                                ),
                                blurRadius: 40,
                                offset: const Offset(0, 26),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _ghostButton(
                                icon: AssetManager.phone,
                                label: context.tr(AuthStrings.signInWithEmail),
                                onTap: () => context.push(AuthRoutes.login),
                              ),
                              12.hBox,
                              _ghostButton(
                                icon: AssetManager.userAddInfo,
                                label: context.tr(AuthStrings.createAccount),
                                onTap: () => context.push(AuthRoutes.register),
                              ),
                              UiSlotRenderer(
                                slot: UiSlot.loginMethods,
                                featureRegistry: context.read<FeatureRegistry>(),
                                padding: const EdgeInsets.only(top: 12),
                                spacing: 12,
                              ),
                              30.hBox,
                              Divider(
                                color: Colors.white.withValues(alpha: 0.14),
                                height: 0.0,
                                thickness: 1.25,
                              ),
                              30.hBox,
                              GestureDetector(
                                onTap: () => context.push(AuthRoutes.privacy),
                                child: Center(
                                  child: Text.rich(
                                    textAlign: TextAlign.center,
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: context.tr(
                                            AuthStrings.bySigningUp,
                                          ),
                                        ),
                                        TextSpan(
                                          text: context.tr(
                                            AuthStrings.termsOfService,
                                          ),
                                          style: const TextStyle(
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor: ColorManager.white,
                                          ),
                                        ),
                                        const TextSpan(text: ' • '),
                                        TextSpan(
                                          text: context.tr(
                                            AuthStrings.privacyPolicy,
                                          ),
                                          style: const TextStyle(
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor: ColorManager.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    style: context.bodyMedium
                                        .size(13)
                                        .colorExt(
                                          ColorManager.white.withValues(
                                            alpha: 0.75,
                                          ),
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ghostButton({
    required String icon,
    required String label,
    required VoidCallback onTap,
    double? size,
    bool isLoading = false,
  }) {
    return ButtonWidget(
      shadowColor: ColorManager.transparent,
      elevation: 0,
      radius: 60.r,
      height: 55,
      onPressed: onTap,
      width: ScreenUtil().screenWidth,
      padding: EdgeInsets.zero,
      paddingButton: EdgeInsets.zero,
      isLoading: isLoading,
      cLoadingColor: ColorManager.primary,
      title: SizedBox(
        width: 290.w,
        child: Row(
          children: [
            5.wBox,
            Image.asset(height: size?.h ?? 35.h, width: size?.w ?? 35.w, icon),
            const Spacer(),
            TextWidget(
              label,
              style: context.bodyMedium.w400
                  .colorExt(ColorManager.blackColor)
                  .copyWith(fontSize: 16.sp),
            ),
            const Spacer(flex: 4),
          ],
        ),
      ),
      backgroundColor: ColorManager.white,
    );
  }
}
