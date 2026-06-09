import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:utd_app/shared/core/color_manager.dart';
import 'package:utd_app/shared/core/extensions.dart';
import 'package:utd_app/shared/widgets/text_widget.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  const AppBarWidget({
    super.key,
    this.title = '',
    this.isShowBack = true,
    this.backgroundColor = Colors.white,
    this.shadow = ColorManager.transparent,
    this.titleStyle,
    this.iconColor,
    this.iconLasted,
    this.height,
    this.actions,
    this.onLeadingPressed,
    this.iconButtonBgColor,
  });

  final dynamic title;
  final bool isShowBack;
  final Color? backgroundColor, iconButtonBgColor;
  final TextStyle? titleStyle;
  final Color? iconColor;
  final Color? shadow;
  final Widget? iconLasted;
  final List<Widget>? actions;
  final double? height;
  final Future<void> Function()? onLeadingPressed;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: height,
      automaticallyImplyLeading: isShowBack,
      elevation: 1,
      scrolledUnderElevation: 1,
      shadowColor: shadow,
      backgroundColor: backgroundColor ?? ColorManager.white,
      leading: isShowBack == false
          ? null
          : IconButton(
              onPressed: () async {
                if (onLeadingPressed != null) {
                  await onLeadingPressed!();
                } else {
                  Navigator.pop(context);
                }
              },
              style: TextButton.styleFrom(
                padding: context.paddingZero(),
                backgroundColor: ColorManager.transparent,
              ),
              icon: Icon(
                Icons.arrow_back_ios,
                size: 20.5.h,
                color: iconColor ?? ColorManager.black,
              ),
            ),
      centerTitle: true,
      title: (title is String)
          ? TextWidget(
              title,
              style:
                  titleStyle ??
                  context.bodyLarge.w600
                      .size(16)
                      .colorExt(ColorManager.blackColor),
            )
          : title,
      actions: actions ?? [iconLasted ?? const SizedBox()],
    );
  }

  @override
  Size get preferredSize =>
      height == null ? AppBar().preferredSize : Size.fromHeight(height ?? 0);
}

class SliverPersistentHeaderWidget extends SliverPersistentHeaderDelegate {
  SliverPersistentHeaderWidget({
    required this.expandedHeight,
    required this.upperWidget,
    required this.background,
  });

  final double expandedHeight;

  // final String title;
  final Widget background;
  final Widget upperWidget;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final size = expandedHeight - shrinkOffset;
    final proportion = 2 - (expandedHeight / size);
    final percent = proportion < 0 || proportion > 1 ? 0.0 : proportion;
    return SizedBox(
      height: expandedHeight + expandedHeight / 2,
      child: Stack(
        children: [
          background,

          Positioned(
            top: ScreenUtil().screenHeight * 0.29,
            right: 5.w,
            left: 5.w,
            child: Opacity(opacity: percent, child: upperWidget),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => expandedHeight + expandedHeight / 2;

  @override
  double get minExtent => expandedHeight / 1.5;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
