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

// TODO: replace with the logged-in patient's AuthAccount once this screen
// receives it from PatientDashboardScreen (same way RoleLandingScreen does).
const String _mockPatientId = '4821';
const String _mockPatientName = 'Tareq';

class PatientHomeScreen extends StatelessWidget {
  const PatientHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);
    final double pad = Sizes.responsivePadding(context);

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
            const StatCardRow(
              stats: [
                StatCardData(label: 'Total Prescriptions', value: 12, icon: Icons.description_outlined),
                StatCardData(label: 'Ongoing Treatments', value: 2, icon: Icons.healing_outlined),
                StatCardData(label: 'Next Appointment', value: 3, suffix: 'd', icon: Icons.event_outlined),
              ],
            ),
            SizedBox(height: pad),
            const NextDoseCard(
              medicineName: 'Metformin 500mg',
              time: 'Today, 2:00 PM',
              adherence: 0.7,
            ),
            SizedBox(height: pad),
            Text('Prescription Timeline', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 14),
            const PrescriptionTimeline(
              entries: [
                PrescriptionTimelineEntry(
                  medicineName: 'Metformin 500mg',
                  dosage: '1 tablet, twice daily',
                  dayCurrent: 12,
                  dayTotal: 30,
                ),
                PrescriptionTimelineEntry(
                  medicineName: 'Amoxicillin 250mg',
                  dosage: '1 capsule, three times daily',
                  dayCurrent: 7,
                  dayTotal: 7,
                ),
              ],
            ),
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
