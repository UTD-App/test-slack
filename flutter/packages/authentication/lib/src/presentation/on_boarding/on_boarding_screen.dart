import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:utd_app/localization/localization_extensions.dart';
import 'package:utd_app/shared/core/shared.dart';
import 'package:authentication/core/asset_manager.dart';

import '../../../core/auth_routes.dart';
import '../../../core/auth_strings.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  State<OnBoardingScreen> createState() => OnBoardingScreenState();
}

class OnBoardingScreenState extends State<OnBoardingScreen> {
  late final List<String> titles;
  late final List<String> subTitles;
  final List<String> images = [
    AssetManager.onboarding1,
    AssetManager.onboarding2,
    AssetManager.onboarding3,
  ];

  int currentPage = 0;
  final PageController pageController = PageController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    titles = [
      context.tr(AuthStrings.onBoarding1Title),
      context.tr(AuthStrings.onBoarding2Title),
      context.tr(AuthStrings.onBoarding3Title),
    ];
    subTitles = [
      context.tr(AuthStrings.onBoarding1Subtitle),
      context.tr(AuthStrings.onBoarding2Subtitle),
      context.tr(AuthStrings.onBoarding3Subtitle),
    ];
  }

  List<String> get buttonText => [
    context.tr(AuthStrings.next),
    context.tr(AuthStrings.next),
    context.tr(AuthStrings.getStarted),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.authBgGradient.last,
      body: GradientBackground(
        colors: ColorManager.authBgGradient,
        child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 80,
            right: 0,
            left: 0,
            bottom: 0,
            child: PageView.builder(
              itemCount: 3,
              onPageChanged: (index) {
                setState(() {
                  currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                return _OnBoardingBody(
                  image: images[index],
                  title: titles[index],
                  subTitle: subTitles[index],
                  index: index,
                  pageController: pageController,
                );
              },
              pageSnapping: true,
              scrollDirection: Axis.horizontal,
              controller: pageController,
            ),
          ),
          Positioned(
            bottom: 140.h,
            child: SmoothPageIndicator(
              controller: pageController,
              count: 3,
              effect: ExpandingDotsEffect(
                dotHeight: 5,
                dotWidth: 12,
                activeDotColor: const Color(0xFFFF5BA6),
                dotColor: ColorManager.white.withValues(alpha: 0.25),
              ),
            ),
          ),
          Positioned(
            bottom: 40.h,
            right: 30.w,
            left: 30.w,
            child: ButtonWidget(
              width: ScreenUtil().screenWidth * 0.8,
              height: ScreenUtil().screenHeight * 0.06,
              onPressed: () async {
                if (currentPage < titles.length - 1) {
                  pageController.nextPage(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                } else {
                  context.go(AuthRoutes.intro);
                }
              },
              title: buttonText[currentPage],
              backgroundColors: ColorManager.pinkCtaGradient,
              radius: 30,
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _OnBoardingBody extends StatelessWidget {
  final int index;
  final String title;
  final String subTitle;
  final String image;
  final PageController pageController;

  const _OnBoardingBody({
    required this.index,
    required this.title,
    required this.subTitle,
    required this.image,
    required this.pageController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Illustration on a soft frosted card so the artwork reads cleanly over
        // the violet gradient regardless of its own backdrop.
        Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: ColorManager.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: ColorManager.frostedBorder),
          ),
          child: Image.asset(image, scale: 4),
        ),
        index == 0 ? 24.0.hBox : 34.0.hBox,
        Text(
          title,
          style: context.bodyMedium
              .size(18)
              .colorExt(ColorManager.white)
              .w700,
        ),
        6.hBox,
        SizedBox(
          width: ScreenUtil().screenWidth * 0.8,
          child: Text(
            subTitle,
            style: context.bodyMedium
                .size(15)
                .colorExt(ColorManager.white.withValues(alpha: 0.75)),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
