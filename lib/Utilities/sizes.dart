import 'package:flutter/material.dart';

class Sizes {
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }
  static double defaultpadding = 20.0;
  static double getAppBarHeight(BuildContext context) {
    return kToolbarHeight;
  }
  static double getBottomNavBarHeight(BuildContext context) {
    return kBottomNavigationBarHeight;
  }
}