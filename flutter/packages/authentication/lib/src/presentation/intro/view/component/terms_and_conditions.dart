import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:utd_app/localization/localization_extensions.dart';
import 'package:utd_app/shared/core/shared.dart';

import '../../../../../core/auth_routes.dart';
import '../../../../../core/auth_strings.dart';

class TermsAndConditions extends StatelessWidget {
  const TermsAndConditions({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(AuthRoutes.privacy),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextWidget(
            context.tr(AuthStrings.haveRead),
            style: context.bodyMedium
                .size(12)
                .colorExt(ColorManager.white)
                .copyWith(decorationColor: ColorManager.primary),
          ),
          TextWidget(
            context.tr(AuthStrings.termsAndCondition),
            style: context.bodyMedium
                .size(12)
                .colorExt(ColorManager.white)
                .copyWith(decorationColor: ColorManager.primary),
          ),
        ],
      ),
    );
  }
}
