import 'package:authentication/core/asset_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:utd_app/localization/localization_extensions.dart';
import 'package:utd_app/shared/core/shared.dart';

import '../../../../../core/auth_routes.dart';
import '../../../../../core/auth_strings.dart';

class RegisterAnimatedDialog extends StatefulWidget {
  final String email;

  const RegisterAnimatedDialog({
    super.key,
    required this.email,
  });

  @override
  RegisterAnimatedDialogState createState() => RegisterAnimatedDialogState();
}

class RegisterAnimatedDialogState extends State<RegisterAnimatedDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          backgroundColor: ColorManager.white,
          insetPadding: EdgeInsets.symmetric(horizontal: 60.w),
          shape: RoundedRectangleBorder(borderRadius: 15.radius),
          elevation: 0.0,
          child: Container(
            decoration: BoxDecoration(
              color: ColorManager.white,
              borderRadius: 20.radius,
            ),
            child: Padding(
              padding: context.paddingAll(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ImageWidget(
                    height: 100.h,
                    width: 100.w,
                    image: AssetManager.mobileValidate,
                  ),
                  10.hBox,
                  TextWidget(
                    context.tr(AuthStrings.notRegisteredYet),
                    textAlign: TextAlign.center,
                    style: context.bodyMedium.w500
                        .size(16)
                        .colorExt(ColorManager.blackColor),
                  ),
                  20.hBox,
                  ButtonWidget(
                    title: context.tr(AuthStrings.registerNow),
                    height: 45.h,
                    fontSize: 14.sp,
                    width: 150.w,
                    titleColor: ColorManager.white,
                    radius: 20,
                    fontWeight: FontWeight.w400,
                    backgroundColor: ColorManager.primary,
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push(
                        AuthRoutes.register,
                        extra: {'email': widget.email},
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
