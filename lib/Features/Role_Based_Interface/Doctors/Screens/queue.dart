import 'package:flutter/material.dart';
import 'package:medicus/Features/Authentication/Models/auth_account.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Screens/doctor_appointments_screen.dart';

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key, required this.account});

  final AuthAccount account;

  @override
  Widget build(BuildContext context) {
    return DoctorAppointmentsScreen(account: account);
  }
}
