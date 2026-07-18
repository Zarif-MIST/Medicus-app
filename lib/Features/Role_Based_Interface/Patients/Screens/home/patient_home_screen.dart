import 'package:flutter/material.dart';
import 'package:medicus/Utilities/helperFunctions.dart';
import 'package:medicus/Utilities/sizes.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Screens/qr/my_qr_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/home/welcome_banner.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/home/qr_scan_button.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/home/stat_card_row.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/home/next_dose_card.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/home/prescription_timeline.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/home/quick_actions_row.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/doctors/booked_appointment.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/records/prescription.dart';

// TODO: replace with the logged-in patient's AuthAccount once this screen
// receives it from PatientDashboardScreen (same way RoleLandingScreen does).
const String _mockPatientId = '4821';
const String _mockPatientName = 'Tareq';

class PatientHomeScreen extends StatelessWidget {
  const PatientHomeScreen({super.key, required this.appointments, required this.prescriptions});

  final List<BookedAppointment> appointments;
  final List<Prescription> prescriptions;

  int get _daysToNextAppointment {
    if (appointments.isEmpty) return 0;
    return appointments.map((a) => a.daysFromNow).reduce((a, b) => a < b ? a : b);
  }

  List<PrescriptionTimelineEntry> get _ongoingPrescriptions {
    final list = prescriptions.expand((p) => p.timelineEntries).where((e) => !e.isCompleted).toList();
    list.sort((a, b) => b.prescribedOn.compareTo(a.prescribedOn));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);
    final double pad = Sizes.responsivePadding(context);
    final List<PrescriptionTimelineEntry> ongoing = _ongoingPrescriptions;

    return Container(
      color: isDark ? const Color(0xFF181818) : Colors.white,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(pad, pad * 0.8, pad, 120),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(child: WelcomeBanner(patientName: _mockPatientName)),
                SizedBox(width: pad * 0.4),
                QrScanButton(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const MyQrScreen(
                        patientId: _mockPatientId,
                        patientName: _mockPatientName,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: pad),
            StatCardRow(
              stats: [
                StatCardData(
                  label: 'Total Prescriptions',
                  value: prescriptions.length,
                  icon: Icons.description_outlined,
                ),
                StatCardData(label: 'Ongoing Treatments', value: ongoing.length, icon: Icons.healing_outlined),
                StatCardData(
                  label: 'Next Appointment',
                  value: _daysToNextAppointment,
                  suffix: 'd',
                  icon: Icons.event_outlined,
                ),
              ],
            ),
            SizedBox(height: pad),
            if (ongoing.isNotEmpty)
              NextDoseCard(
                medicineName: ongoing.first.medicineName,
                time: 'Today, 2:00 PM',
                adherence: 0.7,
              ),
            SizedBox(height: pad),
            Text('Prescription Timeline', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 14),
            if (ongoing.isEmpty)
              Text(
                'No ongoing prescriptions right now.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
              )
            else
              PrescriptionTimeline(entries: ongoing),
            SizedBox(height: pad * 0.6),
            Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 14),
            QuickActionsRow(
              actions: [
                QuickAction(label: 'Order Medicine', icon: Icons.medication_outlined, onTap: () {}),
                QuickAction(label: 'Upload Report', icon: Icons.upload_file_outlined, onTap: () {}),
                QuickAction(label: 'Emergency', icon: Icons.emergency_outlined, onTap: () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
