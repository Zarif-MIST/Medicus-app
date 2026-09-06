import 'package:flutter/material.dart';
import 'package:medicus/Features/Authentication/Models/auth_account.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Models/doctor_appointment_model.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Screens/doctor_home_screen.dart';

/// Full list behind a tapped dashboard stat card (Patients Seen, Pending
/// Cases, Today's Queue) — reuses the same queue tile styling as the home
/// screen, with the AppBar supplying the back button.
class DoctorStatDetailScreen extends StatelessWidget {
  const DoctorStatDetailScreen({
    super.key,
    required this.title,
    required this.account,
    required this.appointments,
    required this.emptyMessage,
  });

  final String title;
  final AuthAccount account;
  final List<DoctorAppointmentModel> appointments;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: appointments.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  emptyMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: appointments.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => DoctorQueueTile(
                account: account,
                appointment: appointments[index],
              ),
            ),
    );
  }
}
