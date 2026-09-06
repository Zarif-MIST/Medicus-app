import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:medicus/Theme/Theme.dart';
import 'package:get/get.dart';
import 'Features/Authentication/Models/auth_account.dart';
import 'Features/Authentication/Models/auth_role.dart';
import 'Features/Authentication/Screens/on_board.dart';
import 'Features/Authentication/Services/auth_registry.dart';
import 'Features/Role_Based_Interface/Doctors/Screens/doctor_dash.dart';
import 'Features/Role_Based_Interface/Lab_Specialist/Screens/lab_dash.dart';
import 'Features/Role_Based_Interface/Patients/Screens/pat_dash.dart';
import 'Features/Role_Based_Interface/Pharmacist/Screens/pharm_dash.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
      home: const _SessionGate(),
    );
  }
}

/// Resumes an already-signed-in user straight into their dashboard instead
/// of the onboarding screen, so the back button doesn't force a fresh login
/// every time the app is reopened.
class _SessionGate extends StatelessWidget {
  const _SessionGate();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AuthAccount?>(
      future: AuthRegistry.instance.currentAccount(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final AuthAccount? account = snapshot.data;
        if (account == null) {
          return OnBoardingScreen();
        }

        switch (account.role) {
          case AuthRole.doctor:
            return DoctorDash(account: account);
          case AuthRole.labSpecialist:
            return LabDashboardScreen(account: account);
          case AuthRole.pharmacist:
            return PharmacistDashboardScreen(account: account);
          case AuthRole.patient:
            return PatientDashboardScreen(account: account);
        }
      },
    );
  }
}
