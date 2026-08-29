import 'package:flutter/material.dart';

class MHelperFunctions {
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// Prefixes a doctor's name with "Dr." unless it already has one — some
  /// older records stored the title as part of the name, current ones don't.
  static String doctorNameWithTitle(String name) {
    return name.trim().toLowerCase().startsWith('dr.') ? name : 'Dr. $name';
  }
}
