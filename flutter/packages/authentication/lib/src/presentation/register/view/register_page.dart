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
        backgroundColor: ColorManager.white,
        appBar: AppBarWidget(
          onLeadingPressed: () async {
            final exit = await showExitDialog(context);
            if (exit && context.mounted) {
              context.pop();
            }
          },
          title: context.tr(AuthStrings.registration),
          backgroundColor: ColorManager.white,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: context.paddingOnly(start: 15, end: 15),
            child: _FormAuthBody(initialEmail: initialEmail),
          ),
        ),
      ),
    );
  }
}

Future<bool> showExitDialog(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
          title: TextWidget(
            context.tr(AuthStrings.exitDialogTitle),
            style: context.bodyMedium
                .size(15)
                .colorExt(ColorManager.blackColor)
                .w500,
          ),
          actions: [
            ButtonWidget(
              backgroundColor: ColorManager.primary,
              title: TextWidget(
                context.tr(AuthStrings.thinkAgain),
                style: context.bodyMedium.colorExt(ColorManager.white),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            20.hBox,
            ButtonWidget(
              backgroundColor: ColorManager.white,
              borderColor: ColorManager.primary,
              title: TextWidget(
                context.tr(AuthStrings.giveUpRegistering),
                style: context.bodyMedium.colorExt(ColorManager.primary),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        ),
      ) ??
      false;
}
