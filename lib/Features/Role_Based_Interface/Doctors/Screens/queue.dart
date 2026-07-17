import 'package:flutter/material.dart';

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Queue'),
      ),
      body: const Center(
        child: Text('Queue Screen'),
      ),
    );
  }
}