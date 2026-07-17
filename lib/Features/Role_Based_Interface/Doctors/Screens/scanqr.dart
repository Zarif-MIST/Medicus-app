import 'package:flutter/material.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Widgets/LiquidNavbar.dart';

class Scanqr extends StatelessWidget {
  const Scanqr({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR'),
      ),
      body: const Center(
        child: Text('Scan QR Screen'),
        
      ),
    );
  }
}