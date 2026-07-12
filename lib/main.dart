import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:medicus/Theme/Theme.dart';
import 'package:get/get.dart';
import 'Features/Authentication/Screens/on_board.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
