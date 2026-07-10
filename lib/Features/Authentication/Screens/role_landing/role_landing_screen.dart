import 'package:flutter/material.dart';

import '../../Models/auth_account.dart';
import 'package:medicus/Features/Authentication/Models/auth_role.dart';

class RoleLandingScreen extends StatelessWidget {
  const RoleLandingScreen({super.key, required this.account});

  final AuthAccount account;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[Color(0xFF92140C), Color(0xFF5D0B07)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Text(
            '${account.role.label}!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ),
    );
  }
}
