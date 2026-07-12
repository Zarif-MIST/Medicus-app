import 'package:flutter/material.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Widgets/LiquidNavbar.dart';
import 'package:medicus/Utilities/helperFunctions.dart';
class DoctorDash extends StatelessWidget {
  const DoctorDash({super.key});
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const HomeShell(),
    );
  }
}
 
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}
 
class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final _items = const [
    LiquidNavItem(icon: Icons.home_outlined, selectedIcon: Icons.home_rounded, label: 'Home'),
    LiquidNavItem(icon: Icons.search, selectedIcon: Icons.search, label: 'Search'),
    LiquidNavItem(icon: Icons.favorite_border, selectedIcon: Icons.favorite, label: 'Saved'),
    LiquidNavItem(icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profile'),
  ];
 
  final _pages = [
    _DemoPage(title: 'Home'),
    _DemoPage(title: 'Search'),
    _DemoPage(title: 'Saved'),
    _DemoPage(title: 'Profile'),
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
 
class _DemoPage extends StatelessWidget {
  final String title;
  const _DemoPage({required this.title, super.key});
 
  @override
  Widget build(BuildContext context) {

    return Container(
      decoration: BoxDecoration(
       color: MHelperFunctions.isDarkMode(context) ? const Color(0xFF181818) : Colors.white,
      ),
      alignment: Alignment.center,
      child: Text(
        title,
        style: const TextStyle(color: Colors.black, fontSize: 32, fontWeight: FontWeight.bold),
      ),
    );
  }
}
 