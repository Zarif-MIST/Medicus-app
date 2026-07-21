import 'package:flutter/material.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Widgets/LiquidNavbar.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Screens/home/patient_home_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Screens/doctors/specialist_selection_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Screens/records/records_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Screens/pharmacies/pharmacy_locator_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Screens/profile/patient_profile_screen.dart';

class PatientDashboardScreen extends StatelessWidget {
  const PatientDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: _PatientHomeShell(),
    );
  }
}

class _PatientHomeShell extends StatefulWidget {
  const _PatientHomeShell();

  @override
  State<_PatientHomeShell> createState() => _PatientHomeShellState();
}

class _PatientHomeShellState extends State<_PatientHomeShell> {
  int _index = 0;

  final _items = const [
    LiquidNavItem(icon: Icons.home_outlined, selectedIcon: Icons.home_rounded, label: 'Home'),
    LiquidNavItem(icon: Icons.calendar_month_outlined, selectedIcon: Icons.calendar_month, label: 'Appointment'),
    LiquidNavItem(icon: Icons.description_outlined, selectedIcon: Icons.description, label: 'Records'),
    LiquidNavItem(icon: Icons.local_pharmacy_outlined, selectedIcon: Icons.local_pharmacy, label: 'Pharmacies'),
    LiquidNavItem(icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profile'),
  ];

  final _pages = const [
    PatientHomeScreen(),
    SpecialistSelectionScreen(),
    RecordsScreen(),
    PharmacyLocatorScreen(),
    PatientProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // extendBody lets page content flow behind the nav bar so the
      // BackdropFilter actually has something colorful to blur.
      extendBody: true,
      body: Stack(
        children: [
          _pages[_index],
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: LiquidGlassNavBar(
              items: _items,
              selectedIndex: _index,
              onTap: (i) => setState(() => _index = i),
            ),
          ),
        ],
      ),
    );
  }
}
