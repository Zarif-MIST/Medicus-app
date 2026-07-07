import 'package:flutter/material.dart';

class MHelperFunctions{
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
}