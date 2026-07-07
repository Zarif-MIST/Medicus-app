import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medicus/Features/Authentication/Screens/login/login.dart';


class OnBoardController extends GetxController {
  static OnBoardController get instance => Get.find();

  final pageController = PageController();
  final currentPageIndex = 0.obs;
  static const _pageAnimationDuration = Duration(milliseconds: 300);
  static const _pageAnimationCurve = Curves.easeInOut;



  void updatePageIndicator(int index) => currentPageIndex.value = index;

  void dotNavClick(int index) {
    currentPageIndex.value = index;
    pageController.animateToPage(
      index,
      duration: _pageAnimationDuration,
      curve: _pageAnimationCurve,
    );

  }

  void nextPage() {
    if (currentPageIndex.value == 2) {
      // Already on last page - navigate to login and remove all previous routes
      Get.offAll(()=>LoginScreen());
    } else {
      int nextPage = currentPageIndex.value + 1;
      pageController.animateToPage(
        nextPage,
        duration: _pageAnimationDuration,
        curve: _pageAnimationCurve,
      );
    }
  }

  void skipPage() {
    // Navigate immediately using GetX with widget
    Get.offAll(
      () => const LoginScreen(),
      transition: Transition.fadeIn
    );
  }

}