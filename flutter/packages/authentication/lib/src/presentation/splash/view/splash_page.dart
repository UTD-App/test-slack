import 'package:authentication/core/asset_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:utd_app/localization/localization_extensions.dart';
import 'package:utd_app/shared/core/shared.dart';

import '../../../../core/auth_strings.dart';
import '../bloc/splash_bloc.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    context.read<SplashBloc>().add(const SplashNavigationEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashBloc, SplashState>(
      listener: (context, state) {
        if (state is SplashResolved) {
          context.go(state.route);
        }
      },
      child: Scaffold(
        backgroundColor: ColorManager.white,
        body: SizedBox(
          width: MediaQuery.sizeOf(context).width,
          height: MediaQuery.sizeOf(context).height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              100.hBox,
              Image.asset(AssetManager.logo, height: 150.h, width: 150.w),
              const Spacer(),
              const CircularProgressIndicator(color: ColorManager.primary),
              10.hBox,
              Text(
                context.tr(AuthStrings.loadingResources),
                style: context.bodySmall.w400.colorExt(ColorManager.grey),
              ),
              30.hBox,
            ],
          ),
        ),
      ),
    );
  }
}
