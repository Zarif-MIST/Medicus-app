import 'package:flutter/material.dart';

class Sizes {
  Sizes._();

  static double screenWidth(BuildContext context) {
    return MediaQuery.sizeOf(context).width;
  }

  static double screenHeight(BuildContext context) {
    return MediaQuery.sizeOf(context).height;
  }

  static const double defaultpadding = 20.0;

  static double getAppBarHeight(BuildContext context) {
    return kToolbarHeight;
  }

  static double getBottomNavBarHeight(BuildContext context) {
    return kBottomNavigationBarHeight;
  }

  static double responsiveWidth(
    BuildContext context,
    double fraction, {
    double min = 0,
    double max = double.infinity,
  }) {
    return (screenWidth(context) * fraction).clamp(min, max).toDouble();
  }

  static double responsiveHeight(
    BuildContext context,
    double fraction, {
    double min = 0,
    double max = double.infinity,
  }) {
    return (screenHeight(context) * fraction).clamp(min, max).toDouble();
  }

  static double responsivePadding(BuildContext context) {
    return responsiveWidth(context, 0.05, min: 16, max: 24);
  }

  static double responsiveFontSize(
    BuildContext context,
    double size, {
    double min = 0,
    double max = double.infinity,
  }) {
    final double scale = screenWidth(context) / 375.0;
    return (size * scale).clamp(min, max).toDouble();
  }
}