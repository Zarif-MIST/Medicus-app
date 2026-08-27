import 'package:flutter/material.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Widgets/LiquidNavbar.dart';
import 'package:medicus/Features/Authentication/Models/auth_account.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Screens/doctor_appointments_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Screens/doctor_home_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Screens/scanqr.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Screens/profile.dart';
import 'package:medicus/Utilities/dashboard_back_guard.dart';

class DoctorDash extends StatelessWidget {
  const DoctorDash({required this.account, super.key});

  final AuthAccount account;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: HomeShell(account: account));
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.account});

  final AuthAccount account;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final _items = const [
    LiquidNavItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Home',
    ),
    LiquidNavItem(
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
      label: 'Schedule',
    ),
    LiquidNavItem(
      icon: Icons.qr_code_scanner_outlined,
      selectedIcon: Icons.qr_code_scanner,
      label: 'Scan QR',
    ),
    LiquidNavItem(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      DoctorHomeScreen(
        account: widget.account,
        onOpenScanner: () => setState(() => _index = 2),
        onOpenAppointments: () => setState(() => _index = 1),
      ),
      DoctorAppointmentsScreen(account: widget.account),
      _index == 2 ? Scanqr(account: widget.account) : const SizedBox.shrink(),
      ProfileScreen(account: widget.account),
    ];

    return DashboardBackGuard(
      isOnHomeTab: _index == 0,
      goToHomeTab: () => setState(() => _index = 0),
      child: Scaffold(
        extendBody: true,
        body: Stack(
          children: [
            IndexedStack(index: _index, children: pages),
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
      ),
    );
  }
}
