import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:get/get.dart';
import 'package:medicus/Features/Authentication/OnBoard/OnBoard_Controller.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/sizes.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnBoardingScreen extends StatelessWidget {
  const OnBoardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final controller = Get.put(OnBoardController());

    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: controller.pageController,
            onPageChanged: controller.updatePageIndicator,
            children: [
              OnBoardPage(
                screenWidth: screenWidth,
                screenHeight: screenHeight,
                images: 'assets/Images/OnBoard/Doctors-bro.svg',
                title: 'Welcome to Medicus',
                subtitle:
                    'Your health companion app for better Healthcare.',
              ),
              OnBoardPage(
                screenWidth: screenWidth,
                screenHeight: screenHeight,
                images: 'assets/Images/OnBoard/Hospital patient-rafiki.svg',
                title: 'All-in-One Health Platform',
                subtitle:
                    'Find all your Tests, Prescriptions and Records in one place.',
              ),
              OnBoardPage(
                screenWidth: screenWidth,
                screenHeight: screenHeight,
                images: 'assets/Images/OnBoard/Pharmacist-bro.svg',
                title: 'Friction-free Platform',
                subtitle:
                    'Find your nearest pharmacy and your favourite doctors',
              ),
            ],
          ),
          Positioned(
            top: Sizes.getAppBarHeight(context) + 20,
            right: 0,
            child: SafeArea(
              right: true,
              top: false,
              bottom: false,
              left: false,
              child: Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => controller.skipPage(),
                  child: Text(
                    'Skip',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
            ),
          ),
          DotNav(),
          Positioned(
            right: 10,
            bottom: Sizes.getBottomNavBarHeight(context),
            child: ElevatedButton(
              onPressed: () => controller.nextPage(),
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                backgroundColor: MColors.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Icon(Iconsax.arrow_circle_right, size: 35),
            ),
          ),
        ],
      ),
    );
  }
}

class DotNav extends StatelessWidget {
  DotNav({super.key});

  final controller = Get.put(OnBoardController());

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: Sizes.getBottomNavBarHeight(context) + 20,
      left: Sizes.defaultpadding + 20,
      right: 0,
      child: SmoothPageIndicator(
        controller: controller.pageController,
        onDotClicked: controller.dotNavClick,
        count: 3,
        effect: ExpandingDotsEffect(
          activeDotColor: MColors.primaryColor,
          dotHeight: 6,
        ),
      ),
    );
  }
}

class OnBoardPage extends StatelessWidget {
  const OnBoardPage({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
    required this.images,
    required this.title,
    required this.subtitle,
  });

  final double screenWidth;
  final double screenHeight;
  final String images, title, subtitle;

  @override
  Widget build(BuildContext context) {
    final double horizontalPadding = (screenWidth * 0.08).clamp(20.0, 32.0);
    final double verticalPadding = (screenHeight * 0.04).clamp(16.0, 28.0);
    final double imageWidth = (screenWidth * 0.78).clamp(240.0, 380.0);
    final double imageHeight = (screenHeight * 0.34).clamp(180.0, 300.0);
    final double titleGap = (screenHeight * 0.03).clamp(16.0, 28.0);

    return SafeArea(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - (verticalPadding * 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    images,
                    width: imageWidth,
                    height: imageHeight,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: titleGap),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: titleGap),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}