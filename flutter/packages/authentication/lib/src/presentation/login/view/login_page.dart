import 'package:authentication/core/asset_manager.dart';
import 'package:authentication/src/presentation/login/view/components/register_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:utd_app/localization/localization_extensions.dart';
import 'package:utd_app/shared/core/shared.dart';
import '../../../../core/auth_routes.dart';
import '../../../../core/auth_strings.dart';
import '../bloc/login_with_phone_bloc/login_bloc.dart';

part 'components/form_auth_body.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.authBgGradient.last,
      extendBodyBehindAppBar: true,
      appBar: const AppBarWidget(
        backgroundColor: ColorManager.transparent,
        iconColor: ColorManager.white,
      ),
      body: GradientBackground(
        colors: ColorManager.authBgGradient,
        child: SafeArea(
          child: Padding(
            padding: context.paddingSymmetric(horizontal: 20),
            child: const _FormAuthBody(),
          ),
        ),
      ),
    );
  }
}
