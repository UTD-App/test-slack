import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:utd_app/localization/localization_extensions.dart';
import 'package:utd_app/shared/core/shared.dart';

import '../../../../core/auth_strings.dart';
import '../bloc/recover_password_bloc.dart';

part 'components/recover_password_body.dart';

/// 3-step WhatsApp-OTP password recovery (enter phone → code → new password).
/// The single GoRoute hosts all steps; the active step lives in the bloc state.
class RecoverPasswordPage extends StatelessWidget {
  const RecoverPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.authBgGradient.last,
      extendBodyBehindAppBar: true,
      appBar: AppBarWidget(
        title: context.tr(AuthStrings.recoverPassword),
        backgroundColor: ColorManager.transparent,
        iconColor: ColorManager.white,
        titleStyle:
            context.bodyLarge.w600.size(16).colorExt(ColorManager.white),
        onLeadingPressed: () async {
          // From a later step, go back one step instead of leaving the screen.
          final bloc = context.read<RecoverPasswordBloc>();
          if (bloc.state.step != RecoverStep.enterEmail) {
            bloc.add(const RecoverBackToStartEvent());
          } else {
            context.pop();
          }
        },
      ),
      body: GradientBackground(
        colors: ColorManager.authBgGradient,
        child: SafeArea(
          child: Padding(
            padding: context.paddingSymmetric(horizontal: 20),
            child: const _RecoverPasswordBody(),
          ),
        ),
      ),
    );
  }
}
