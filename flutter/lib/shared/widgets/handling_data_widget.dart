import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:lottie/lottie.dart';
import 'package:utd_app/config/asset_manager.dart';
import 'package:utd_app/localization/localization_extensions.dart';
import 'package:utd_app/shared/core/color_manager.dart';
import 'package:utd_app/shared/core/enums.dart';
import 'package:utd_app/shared/core/extensions.dart';
import 'package:utd_app/shared/widgets/button_widget.dart';
import 'package:utd_app/shared/widgets/text_widget.dart';

class HandlingDataWidget extends StatelessWidget {
  const HandlingDataWidget({
    super.key,
    required this.reqState,
    this.childEmpty,
    required this.title,
    required this.subTitle,
    this.onTap,
    this.isBlock,
    this.buttonTitle,
    this.titleStyle,
    this.subTitleStyle,
    this.isLoadingCenter,
    this.isNeedLoadingWidget = true,
    required this.child,
  });

  final RequestState reqState;
  final Widget child;
  final Widget? childEmpty;
  final String? isBlock;
  final String? buttonTitle;
  final String title, subTitle;
  final VoidCallback? onTap;
  final TextStyle? titleStyle;
  final TextStyle? subTitleStyle;
  final bool? isNeedLoadingWidget;
  final bool? isLoadingCenter;
  @override
  Widget build(BuildContext context) {
    if (reqState.isLoading) {
      return (isNeedLoadingWidget == false)
          ? child
          : LoadingView(isLoadingCenter: isLoadingCenter);
    } else if (reqState.isError) {
      return ErrorView(
        onTap: onTap,
        isBlock: isBlock,
        subTitleStyle: subTitleStyle,
        titleStyle: titleStyle,
      );
    } else if (reqState.isOffline) {
      return _OfflineView(
        onTap: onTap,
        subTitleStyle: subTitleStyle,
        titleStyle: titleStyle,
      );
    } else if (reqState.userBan) {
      return BanUserWidget(
        onTap: onTap,
        subTitleStyle: subTitleStyle,
        titleStyle: titleStyle,
        title: title,
        message: subTitle,
      );
    } else if (reqState.isEmpty) {
      return childEmpty ??
          EmptyView(
            title: title,
            subTitle: subTitle,
            onTap: onTap,
            subTitleStyle: subTitleStyle,
            titleStyle: titleStyle,
            buttonTitle: buttonTitle,
          );
    } else {
      return child;
    }
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.isLoadingCenter});

  final bool? isLoadingCenter;
  @override
  Widget build(BuildContext context) {
    return isLoadingCenter ?? false
        ? SizedBox(
            height: 320.h,
            child: LoadingAnimationWidget.staggeredDotsWave(
              color: ColorManager.primary,
              size: 30.h,
            ),
          )
        : Center(
            child: LoadingAnimationWidget.staggeredDotsWave(
              color: ColorManager.primary,
              size: 30.h,
            ),
          );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    this.onTap,
    this.isBlock,
    this.subTitleStyle,
    this.titleStyle,
  });
  final VoidCallback? onTap;
  final String? isBlock;
  final TextStyle? titleStyle;
  final TextStyle? subTitleStyle;

  @override
  Widget build(BuildContext context) {
    return ErrorOrEmptyWidget(
      image: AssetsManager.error,
      title: context.tr('app.error'),
      message: isBlock ?? context.tr('app.error'),
      onTap: onTap,
      titleStyle: titleStyle,
      subTitleStyle: subTitleStyle,
    );
  }
}

class _OfflineView extends StatelessWidget {
  const _OfflineView({this.onTap, this.subTitleStyle, this.titleStyle});

  final VoidCallback? onTap;
  final TextStyle? titleStyle;
  final TextStyle? subTitleStyle;

  @override
  Widget build(BuildContext context) {
    return ErrorOrEmptyWidget(
      image: AssetsManager.noWifi,
      title: context.tr('app.error'),
      message: context.tr('app.no_connection'),
      onTap: onTap,
      titleStyle: titleStyle,
      subTitleStyle: subTitleStyle,
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    this.onTap,
    required this.title,
    this.titleStyle,
    this.subTitleStyle,
    this.buttonTitle,
    required this.subTitle,
  });
  final String title, subTitle;
  final String? buttonTitle;
  final VoidCallback? onTap;
  final TextStyle? titleStyle;
  final TextStyle? subTitleStyle;

  @override
  Widget build(BuildContext context) {
    return ErrorOrEmptyWidget(
      image: AssetsManager.empty,
      title: title,
      message: subTitle,
      onTap: onTap,
      titleStyle: titleStyle,
      subTitleStyle: subTitleStyle,
      buttonTitle: buttonTitle,
    );
  }
}

class ErrorOrEmptyWidget extends StatelessWidget {
  const ErrorOrEmptyWidget({
    super.key,
    required this.image,
    required this.title,
    required this.message,
    this.onTap,
    this.size,
    this.titleStyle,
    this.subTitleStyle,
    this.buttonTitle,
    this.buttonColor,
  });

  final String image;
  final String? buttonTitle;
  final String title;
  final String message;
  final VoidCallback? onTap;
  final double? size;
  final TextStyle? titleStyle;
  final TextStyle? subTitleStyle;
  final Color? buttonColor;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: context.paddingOnly(start: 10, end: 10),
      child: Align(
        alignment: AlignmentDirectional.center,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (image.isNotEmpty)
              Padding(
                padding: context.paddingOnly(
                  end: image == AssetsManager.loading ? 15 : 0,
                ),
                child: Lottie.asset(
                  image,
                  height: size?.h ?? 90.h,
                  width: size?.w ?? 90.w,
                ),
              ),
            TextWidget(
              title,
              textAlign: TextAlign.center,
              style:
                  titleStyle ??
                  context.bodyLarge.w600.colorExt(ColorManager.blackColor),
            ),
            5.hBox,
            TextWidget(
              message,
              textAlign: TextAlign.center,
              style:
                  subTitleStyle ??
                  context.bodyMedium.copyWith(
                    color: ColorManager.greyTextColor,
                    height: 1.30,
                  ),
            ),
            if (onTap != null) ...[
              30.hBox,
              Padding(
                padding: context.paddingSymmetric(horizontal: 30),
                child: ButtonWidget(
                  title: buttonTitle ?? context.tr('app.retry'),
                  backgroundColor: buttonColor ?? ColorManager.transparent,
                  titleColor: ColorManager.primary,
                  borderColor: ColorManager.primary,
                  fontWeight: FontWeight.w400,
                  onPressed: onTap ?? () {},
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class BanUserWidget extends StatelessWidget {
  const BanUserWidget({
    super.key,
    required this.title,
    required this.message,
    this.onTap,
    this.size,
    this.titleStyle,
    this.subTitleStyle,
    this.buttonTitle,
    this.buttonColor,
  });

  final String? buttonTitle;
  final String title;
  final String message;
  final VoidCallback? onTap;
  final double? size;
  final TextStyle? titleStyle;
  final TextStyle? subTitleStyle;
  final Color? buttonColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: context.paddingOnly(start: 10, end: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            AssetsManager.ban,
            height: size?.h ?? 90.h,
            width: size?.w ?? 90.w,
          ),
          10.hBox,
          TextWidget(
            title,
            textAlign: TextAlign.center,
            style:
                titleStyle ??
                context.bodyLarge.w600.colorExt(ColorManager.redAccount),
          ),
          5.hBox,
        ],
      ),
    );
  }
}
