import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:utd_app/localization/localization_extensions.dart';
import 'package:utd_app/shared/core/shared.dart';

import '../../../../core/auth_strings.dart';
import '../bloc/register_bloc.dart';

part 'components/form_auth_body.dart';

class RegisterPage extends StatelessWidget {
  final String? initialEmail;

  const RegisterPage({
    super.key,
    this.initialEmail,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final exit = await showExitDialog(context);
        if (exit && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: ColorManager.authBgGradient.last,
        extendBodyBehindAppBar: true,
        appBar: AppBarWidget(
          onLeadingPressed: () async {
            final exit = await showExitDialog(context);
            if (exit && context.mounted) {
              context.pop();
            }
          },
          title: context.tr(AuthStrings.registration),
          backgroundColor: ColorManager.transparent,
          iconColor: ColorManager.white,
          titleStyle: context.bodyLarge.w600
              .size(16)
              .colorExt(ColorManager.white),
        ),
        body: GradientBackground(
          colors: ColorManager.authBgGradient,
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: context.paddingOnly(start: 15, end: 15),
                child: _FormAuthBody(initialEmail: initialEmail),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<bool> showExitDialog(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => Dialog(
          backgroundColor: ColorManager.transparent,
          child: GradientCard(
            radius: 20,
            padding: EdgeInsets.all(20.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextWidget(
                  context.tr(AuthStrings.exitDialogTitle),
                  textAlign: TextAlign.center,
                  style: context.bodyMedium
                      .size(16)
                      .w600
                      .colorExt(ColorManager.white),
                ),
                20.hBox,
                SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: ColorManager.pinkCtaGradient,
                      ),
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: Text(
                        context.tr(AuthStrings.thinkAgain),
                        style: const TextStyle(
                          color: ColorManager.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                8.hBox,
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: Text(
                      context.tr(AuthStrings.giveUpRegistering),
                      style: const TextStyle(
                        color: ColorManager.lumiaTextSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ) ??
      false;
}
