import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:utd_app/localization/localization_extensions.dart';
import 'package:utd_app/shared/core/extensions.dart';
import 'package:utd_app/shared/widgets/loading_widget.dart';
import 'package:utd_app/shared/widgets/text_widget.dart';
import 'color_manager.dart';

class ToastManager {
  ToastManager._();

  static void showToast(
    BuildContext context, {
    String message = '',
    bool isError = false,
    bool isLoading = false,
  }) {
    final navigator = Navigator.maybeOf(context);
    if (navigator == null) return;

    final overlayState = navigator.overlay;
    if (overlayState == null) return;

    final animationController = AnimationController(
      vsync: overlayState,
      duration: const Duration(milliseconds: 300),
    );

    final fadeAnimation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOut,
    );

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 100.0.h,
        left: 50.w,
        right: 50.w,
        child: Align(
          alignment: AlignmentDirectional.topCenter,
          child: Material(
            color: ColorManager.transparent,
            borderRadius: MediaQuery.sizeOf(context).width.radius,
            child: FadeTransition(
              opacity: fadeAnimation,
              child: IntrinsicWidth(
                child: Container(
                  padding: context.paddingSymmetric(
                    vertical: 7.5,
                    horizontal: 15,
                  ),
                  decoration: BoxDecoration(
                    color: isLoading
                        ? ColorManager.black
                        : isError
                        ? ColorManager.redAccount
                        : const Color(0xFF43A047),
                    borderRadius: MediaQuery.sizeOf(context).width.radius,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isLoading) ...[
                        Padding(
                          padding: context.paddingSymmetric(horizontal: 7.5),
                          child: const LoadingWidget(),
                        ),
                        10.wBox,
                      ],
                      Expanded(
                        child: TextWidget(
                          isLoading ? context.tr('app.loading') : message,
                          textAlign: TextAlign.center,
                          maxLines: 10,
                          overflow: TextOverflow.ellipsis,
                          style: context.bodyMedium.colorExt(
                            ColorManager.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlayState.insert(overlayEntry);
    animationController.forward();

    Future.delayed(const Duration(seconds: 2), () {
      animationController.reverse().then((_) {
        overlayEntry.remove();
        animationController.dispose();
      });
    });
  }
}
