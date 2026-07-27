import 'package:flutter/material.dart';
import 'package:medicus/Features/Authentication/Models/auth_account.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Widgets/LiquidSearchBar.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Widgets/customShapes.dart';
import 'package:medicus/Utilities/helperFunctions.dart';
import 'package:medicus/Utilities/sizes.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Screens/qr/my_qr_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/home/stat_card_row.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/home/next_dose_card.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/home/prescription_timeline.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/home/quick_actions_row.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/doctors/booked_appointment.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/records/prescription.dart';
import 'package:medicus/Utilities/colors.dart';

// TODO: replace with the logged-in patient's AuthAccount once this screen
// receives it from PatientDashboardScreen (same way RoleLandingScreen does).
const String _mockPatientId = '4821';
const String _mockPatientName = 'Tareq';

class PatientHomeScreen extends StatelessWidget {
  const PatientHomeScreen({
    super.key,
    required this.account,
    required this.appointments,
    required this.prescriptions,
  });

  final AuthAccount account;

  final List<BookedAppointment> appointments;
  final List<Prescription> prescriptions;

  int get _daysToNextAppointment {
    if (appointments.isEmpty) return 0;
    return appointments
        .map((a) => a.daysFromNow)
        .reduce((a, b) => a < b ? a : b);
  }

  List<PrescriptionTimelineEntry> get _ongoingPrescriptions {
    final list = prescriptions
        .expand((p) => p.timelineEntries)
        .where((e) => !e.isCompleted)
        .toList();
    list.sort((a, b) => b.prescribedOn.compareTo(a.prescribedOn));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);
    final double pad = Sizes.responsivePadding(context);
    final List<PrescriptionTimelineEntry> ongoing = _ongoingPrescriptions;
    final String patientName = account.firstName.isEmpty
        ? _mockPatientName
        : account.firstName;
    final String patientId = account.userId.isEmpty
        ? _mockPatientId
        : account.userId;

    return Container(
      color: isDark ? const Color(0xFF181818) : Colors.white,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            ClipPath(
              clipper: MCurvedEdges(),
              child: Container(
                color: MColors.primaryColor,
                child: SizedBox(
                  height: 390,
                  child: Stack(
                    children: [
                      const Positioned(
                        top: -150,
                        right: -250,
                        child: _PatientCircleAccent(),
                      ),
                      const Positioned(
                        top: 100,
                        right: -300,
                        child: _PatientCircleAccent(),
                      ),
                      Positioned.fill(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: pad),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 50),
                              const Text(
                                'Welcome back,',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                patientName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 28),
                              LiquidGlassSearchBar(
                                hintText: 'Search doctor, medicine, or record',
                                onChanged: (_) {},
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: () =>
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => MyQrScreen(
                                                patientId: patientId,
                                                patientName: patientName,
                                              ),
                                            ),
                                          ),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: MColors.primaryColor,
                                      ),
                                      icon: const Icon(
                                        Icons.qr_code_2_outlined,
                                      ),
                                      label: const Text('My QR Code'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: () {},
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.white
                                            .withValues(alpha: 0.16),
                                        foregroundColor: Colors.white,
                                      ),
                                      icon: const Icon(
                                        Icons.calendar_month_outlined,
                                      ),
                                      label: const Text('Appointments'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(pad, 12, pad, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatCardRow(
                    stats: [
                      StatCardData(
                        label: 'Total Prescriptions',
                        value: prescriptions.length,
                        icon: Icons.description_outlined,
                      ),
                      StatCardData(
                        label: 'Ongoing Treatments',
                        value: ongoing.length,
                        icon: Icons.healing_outlined,
                      ),
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
                  Text(
                    'Prescription Timeline',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 14),
                  if (ongoing.isEmpty)
                    Text(
                      'No ongoing prescriptions right now.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    )
                  else
                    PrescriptionTimeline(entries: ongoing),
                  SizedBox(height: pad * 0.6),
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 14),
                  QuickActionsRow(
                    actions: [
                      QuickAction(
                        label: 'Order Medicine',
                        icon: Icons.medication_outlined,
                        onTap: () {},
                      ),
                      QuickAction(
                        label: 'Upload Report',
                        icon: Icons.upload_file_outlined,
                        onTap: () {},
                      ),
                      QuickAction(
                        label: 'Emergency',
                        icon: Icons.emergency_outlined,
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientCircleAccent extends StatelessWidget {
  const _PatientCircleAccent();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(400),
      ),
    );
  }
}
