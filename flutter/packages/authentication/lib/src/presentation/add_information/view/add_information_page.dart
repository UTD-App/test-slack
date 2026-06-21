import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:utd_app/localization/localization_extensions.dart';
import 'package:utd_app/shared/core/shared.dart';
import 'package:utd_app/shared/media/media_service.dart';

import '../../../../core/auth_strings.dart';
import '../bloc/add_information_bloc.dart';
import 'package:authentication/core/asset_manager.dart';
part 'components/form_add_info_body.dart';
part 'components/pick_image_body.dart';

class AddInformationPage extends StatelessWidget {
  const AddInformationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fallback colour for the system-nav area + edge-to-edge body so the
      // gradient covers the whole screen (no black strip at the bottom).
      backgroundColor: ColorManager.authBgGradient.last,
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: GradientBackground(
        colors: ColorManager.authBgGradient,
        child: PopScope(
          canPop: false,
          child: SafeArea(
            child: SingleChildScrollView(
              child: BlocBuilder<AddInformationBloc, AddInformationState>(
                buildWhen: (prev, curr) => prev != curr,
                builder: (context, state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      40.hBox,
                      TextWidget(
                        context.tr(AuthStrings.hiTemp),
                        padding: context.paddingSymmetric(horizontal: 20),
                        style: context.bodyMedium.bold
                            .size(30)
                            .colorExt(ColorManager.white),
                      ),
                      6.hBox,
                      TextWidget(
                        context.tr(AuthStrings.improveTheInfo),
                        padding: context.paddingSymmetric(horizontal: 20),
                        style: context.bodySmall.w500
                            .colorExt(ColorManager.lumiaTextSecondary)
                            .size(14),
                      ),
                      30.hBox,
                      _FormAddInfoBody(state: state),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
