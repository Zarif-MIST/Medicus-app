import 'package:flutter/material.dart';
import 'package:medicus/Theme/Custom_themes/Text_theme.dart';

class MTheme {
  MTheme._();
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    fontFamily: 'Poppins',
    scaffoldBackgroundColor: Colors.white,
    textTheme: MTextTheme.lightTextTheme,
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    fontFamily: 'Poppins',
    scaffoldBackgroundColor: const Color(0xFF181818),
    textTheme: MTextTheme.darkTextTheme,
  );
}
