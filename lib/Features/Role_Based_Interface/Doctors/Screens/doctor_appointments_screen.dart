import 'package:flutter/material.dart';
import 'package:medicus/Features/Authentication/Models/auth_account.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Models/doctor_appointment_model.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Screens/patient_detail_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Screens/prescription_form_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Services/doctor_service.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key, required this.account});

  final AuthAccount account;

  @override
  State<DoctorAppointmentsScreen> createState() =>
      _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
  late Future<List<DoctorAppointmentModel>> _appointmentsFuture;

  @override
  void initState() {
    super.initState();
    _appointmentsFuture = DoctorService.instance.getTodayAppointments(
      widget.account,
    );
  }

  Future<void> _openPatient(
    BuildContext context,
    DoctorAppointmentModel appointment,
  ) async {
    final record = await DoctorService.instance.getPatientRecordById(
      appointment.patientId,
    );
    if (!context.mounted || record == null) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PatientDetailScreen(record: record)),
    );
  }

  Future<void> _openPrescription(
    BuildContext context,
    DoctorAppointmentModel appointment,
  ) async {
    final record = await DoctorService.instance.getPatientRecordById(
      appointment.patientId,
    );
    if (!context.mounted || record == null) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            PrescriptionFormScreen(doctor: widget.account, patient: record),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF181818)
          : const Color(0xFFF7F5F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Today's Appointments"),
      ),
      body: FutureBuilder<List<DoctorAppointmentModel>>(
        future: _appointmentsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load appointments.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: MColors.primaryColor),
            );
          }

          final appointments = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            itemCount: appointments.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final appointment = appointments[index];

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.26 : 0.05,
                      ),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.patientName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${appointment.timeLabel} • ${appointment.reason}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _openPatient(context, appointment),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: MColors.primaryColor,
                              ),
                              foregroundColor: MColors.primaryColor,
                            ),
                            child: const Text('View Record'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () =>
                                _openPrescription(context, appointment),
                            style: FilledButton.styleFrom(
                              backgroundColor: MColors.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Write Rx'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
