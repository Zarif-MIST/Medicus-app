import 'package:flutter/material.dart';
import 'package:medicus/Features/Authentication/Models/auth_account.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Screens/profile.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Screens/scanqr.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Widgets/LiquidNavbar.dart';
import 'package:medicus/Features/Role_Based_Interface/Lab_Specialist/Screens/lab_home_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Lab_Specialist/Screens/lab_results_screen.dart';
import 'package:medicus/Utilities/dashboard_back_guard.dart';

class LabDashboardScreen extends StatelessWidget {
  const LabDashboardScreen({super.key, required this.account});

  final AuthAccount account;

  @override
  Widget build(BuildContext context) {
    return _LabShell(account: account);
  }
}

class _LabShell extends StatefulWidget {
  const _LabShell({required this.account});

  final AuthAccount account;

  @override
  State<_LabShell> createState() => _LabShellState();
}

class _LabShellState extends State<_LabShell> {
  int _index = 0;
  final GlobalKey<LabHomeScreenState> _homeKey =
      GlobalKey<LabHomeScreenState>();

  final List<LiquidNavItem> _items = const [
    LiquidNavItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Home',
    ),
    LiquidNavItem(
      icon: Icons.qr_code_scanner_outlined,
      selectedIcon: Icons.qr_code_scanner,
      label: 'Scan QR',
    ),
    LiquidNavItem(
      icon: Icons.upload_file_outlined,
      selectedIcon: Icons.upload_file,
      label: 'Results',
    ),
    LiquidNavItem(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: 'Profile',
    ),
  ];

  void _onNavTap(int index) {
    setState(() => _index = index);
    if (index == 0) {
      _homeKey.currentState?.refreshOrdersData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      LabHomeScreen(key: _homeKey, account: widget.account),
      _index == 1 ? Scanqr(account: widget.account) : const SizedBox.shrink(),
      const LabResultsScreen(),
      ProfileScreen(account: widget.account),
    ];

    return DashboardBackGuard(
      isOnHomeTab: _index == 0,
      goToHomeTab: () => _onNavTap(0),
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
                onTap: _onNavTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
