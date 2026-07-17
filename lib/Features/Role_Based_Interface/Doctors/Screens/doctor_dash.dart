import 'package:flutter/material.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Widgets/LiquidNavbar.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Widgets/customShapes.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Screens/scanqr.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Screens/queue.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Screens/profile.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Widgets/LiquidSearchBar.dart';
import 'package:medicus/Features/Authentication/Models/auth_account.dart';
class DoctorDash extends StatelessWidget {
  const DoctorDash({required this.account, super.key});
  final AuthAccount account;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:  HomeShell(),
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
    LiquidNavItem(icon: Icons.queue_outlined, selectedIcon: Icons.queue, label: 'Queue'),
    LiquidNavItem(icon: Icons.qr_code_scanner_outlined, selectedIcon: Icons.qr_code_scanner, label: 'Scan QR'),
    LiquidNavItem(icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profile'),
  ];
 
  final _pages = [
    _DemoPage(title: 'Home'),
    QueueScreen(),
    Scanqr(),
    ProfileScreen(),
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
  const _DemoPage({required this.title});
  String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good Morning,';
  if (hour < 17) return 'Good Afternoon,';
  return 'Good Evening,';
}
  @override
  Widget build(BuildContext context) {

    return Scaffold(
  body: SingleChildScrollView(
    child: Column(
      children: [
        ClipPath(
          clipper: MCurvedEdges(),
          child: Container(
            color: MColors.primaryColor,
            padding: EdgeInsets.all(0),
            child: SizedBox(
              height: 380,
              child: Stack(
                children: [
                  Positioned(top: -150, right: -250, child: MCircularPath()),
                  Positioned(top: 100, right: -300, child: MCircularPath()),

                  // Greeting + search bar, on top of the decorative circles
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 50),
                            Text(
                              _greeting(),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Dr. Sarah Ahmed', // swap for your doctor name variable
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 30),
                            LiquidGlassSearchBar(
                              hintText: 'Search patient ID',
                              onChanged: (value) {
                                // hook up your patient search here
                              },
                              onSubmitted: (value) {
                                // e.g. navigate to patient record
                              },
                            ),
                            const SizedBox(height: 35),
                            GestureDetector(
                              onTap: () {
                                // navigate to QR scanner page
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const Scanqr()),
                                );
                              },
                              child: Icon(Icons.qr_code_scanner, color: Colors.white, size: 35),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  ),
);
  }
}

class MCircularPath extends StatelessWidget {
  const MCircularPath({
    super.key,
    this.radius =400,
    this.width =400,
    this.height = 400,
    this.padding = 0,
    this.child,
    this.backgroundColor = Colors.white,
  });
  final double? radius;
  final double? width;
  final double height;
  final double padding;
  final Widget? child;
  final Color backgroundColor;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius!),
        color: backgroundColor.withOpacity(0.1),
      ),
    );
  }
}
 