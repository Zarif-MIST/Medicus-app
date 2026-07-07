import 'package:flutter/material.dart';
import 'package:medicus/Theme/Theme.dart';
import 'package:get/get.dart';
import 'Features/Authentication/Screens/OnBoard.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      themeMode: ThemeMode.system,
      theme: MTheme.lightTheme,
      darkTheme: MTheme.darkTheme,
      home: OnBoardingScreen(),
    );
  }
}