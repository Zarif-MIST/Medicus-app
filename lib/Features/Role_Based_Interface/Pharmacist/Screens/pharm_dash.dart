import 'package:flutter/material.dart';
import 'package:medicus/Features/Authentication/Models/auth_account.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Widgets/LiquidNavbar.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Screens/scanqr.dart';
import 'package:medicus/Features/Role_Based_Interface/Pharmacist/Screens/inventory_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Pharmacist/Screens/pharmacist_home_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Screens/profile.dart';

class PharmacistDashboardScreen extends StatelessWidget {
  const PharmacistDashboardScreen({super.key, required this.account});

  final AuthAccount account;

  @override
  Widget build(BuildContext context) {
    return _PharmacistShell(account: account);
  }
}

class _PharmacistShell extends StatefulWidget {
  const _PharmacistShell({required this.account});

  final AuthAccount account;

  @override
  State<_PharmacistShell> createState() => _PharmacistShellState();
}

class _PharmacistShellState extends State<_PharmacistShell> {
  int _index = 0;
  final GlobalKey<PharmacistHomeScreenState> _homeKey =
      GlobalKey<PharmacistHomeScreenState>();

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
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
      label: 'Inventory',
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
      PharmacistHomeScreen(
        key: _homeKey,
        account: widget.account,
        onOpenInventory: () => setState(() => _index = 2),
      ),
      Scanqr(account: widget.account),
      const InventoryScreen(),
      ProfileScreen(account: widget.account),
    ];

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          pages[_index],
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: LiquidGlassNavBar(
              items: _items,
              selectedIndex: _index,
              onTap: (index) => setState(() => _index = index),
            ),
          ),
        ],
      ),
    );
  }
}
