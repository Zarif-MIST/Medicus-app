import 'package:flutter/material.dart';

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