import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:utd_app/localization/localization_extensions.dart';
import 'package:utd_app/shared/core/shared.dart';

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
      backgroundColor: ColorManager.white,
      body: PopScope(
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
                    30.hBox,
                    TextWidget(
                      context.tr(AuthStrings.hiTemp),
                      padding: context.paddingSymmetric(horizontal: 10),
                      style: context.bodyMedium.bold
                          .size(22)
                          .colorExt(ColorManager.textTabBar),
                    ),
                    2.hBox,
                    TextWidget(
                      context.tr(AuthStrings.improveTheInfo),
                      padding: context.paddingSymmetric(horizontal: 10),
                      textAlign: TextAlign.center,
                      style: context.bodySmall.w500
                          .colorExt(ColorManager.blackColor)
                          .size(14),
                    ),
                    40.hBox,
                    _FormAddInfoBody(state: state),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
