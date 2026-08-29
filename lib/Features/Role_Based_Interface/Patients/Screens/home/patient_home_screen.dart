import 'package:flutter/material.dart';
import 'package:medicus/Features/Authentication/Models/auth_account.dart';
import 'package:medicus/Features/Prescriptions/Models/prescription_record.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Widgets/LiquidSearchBar.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Widgets/customShapes.dart';
import 'package:medicus/Utilities/helperFunctions.dart';
import 'package:medicus/Utilities/sizes.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Screens/qr/my_qr_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Screens/records/prescription_medicines_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Screens/records/records_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Screens/records/upload_report_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Screens/search/patient_search_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/home/stat_card_row.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/home/appointment_calendar_sheet.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/home/emergency_hospitals_sheet.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/home/next_appointment_card.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/home/next_dose_card.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/home/notifications_sheet.dart';
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
    required this.prescriptionRecords,
    required this.onBookAppointment,
    required this.medicalInfoIncomplete,
    required this.onCompleteMedicalInfo,
  });

  final AuthAccount account;

  final List<BookedAppointment> appointments;
  final List<Prescription> prescriptions;
  final List<PrescriptionRecord> prescriptionRecords;
  final ValueChanged<BookedAppointment> onBookAppointment;
  final bool medicalInfoIncomplete;
  final VoidCallback onCompleteMedicalInfo;

  /// Only appointments today or later — a past booking should never be
  /// mistaken for "next", which is what let a stale/previous appointment
  /// show up here instead of a newly booked upcoming one.
  List<BookedAppointment> get _upcomingAppointments {
    final DateTime today = DateTime.now();
    final DateTime todayOnly = DateTime(today.year, today.month, today.day);
    return appointments
        .where((a) => !DateTime(a.date.year, a.date.month, a.date.day).isBefore(todayOnly))
        .toList();
  }

  int get _daysToNextAppointment {
    final List<BookedAppointment> upcoming = _upcomingAppointments;
    if (upcoming.isEmpty) return 0;
    return upcoming
        .map((a) => a.daysFromNow)
        .reduce((a, b) => a < b ? a : b);
  }

  BookedAppointment? get _nextAppointment {
    final List<BookedAppointment> upcoming = _upcomingAppointments;
    if (upcoming.isEmpty) return null;
    final List<BookedAppointment> sorted = [...upcoming]..sort((a, b) => a.date.compareTo(b.date));
    return sorted.first;
  }

  List<PrescriptionTimelineEntry> get _ongoingPrescriptions {
    final list = prescriptions
        .expand((p) => p.timelineEntries)
        .where((e) => !e.isCompleted)
        .toList();
    list.sort((a, b) => b.prescribedOn.compareTo(a.prescribedOn));
    return list;
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
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
                  height: 290,
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
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.18),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Text(
                                      patientName.isNotEmpty ? patientName[0].toUpperCase() : 'P',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _greeting,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          patientName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Material(
                                    color: Colors.white.withValues(alpha: 0.14),
                                    shape: const CircleBorder(),
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: () => showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (_) => NotificationsSheet(
                                          patientId: patientId,
                                          nextAppointment: _nextAppointment,
                                          activePrescriptions: prescriptionRecords,
                                        ),
                                      ),
                                      child: const Padding(
                                        padding: EdgeInsets.all(10),
                                        child: Icon(
                                          Icons.notifications_none_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 26),
                              LiquidGlassSearchBar(
                                hintText: 'Search doctors, pharmacies, hospitals…',
                                onSubmitted: (value) => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PatientSearchScreen(
                                      initialQuery: value,
                                      prescriptions: prescriptions,
                                      appointments: appointments,
                                      onBookAppointment: onBookAppointment,
                                      patientId: patientId,
                                      patientName: patientName,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Align(
                                alignment: Alignment.center,
                                child: IconButton(
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => MyQrScreen(
                                        patientId: patientId,
                                        patientName: patientName,
                                      ),
                                    ),
                                  ),
                                  icon: const Icon(Icons.qr_code_2_outlined),
                                  color: Colors.white,
                                  iconSize: 30,
                                ),
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
            SizedBox(height: pad * 0.2),
            Padding(
              padding: EdgeInsets.fromLTRB(pad, 0, pad, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (medicalInfoIncomplete) ...[
                    _MedicalInfoBanner(onTap: onCompleteMedicalInfo),
                    SizedBox(height: pad),
                  ],
                  StatCardRow(
                    highlightIndex: 2,
                    onHighlightTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => AppointmentCalendarSheet(appointments: appointments),
                    ),
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
                  if (_nextAppointment != null) ...[
                    SizedBox(height: pad),
                    NextAppointmentCard(
                      appointment: _nextAppointment!,
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => AppointmentCalendarSheet(appointments: appointments),
                      ),
                    ),
                  ],
                  if (prescriptionRecords.isNotEmpty) ...[
                    SizedBox(height: pad),
                    NextDoseCard(
                      patientId: patientId,
                      activePrescriptions: prescriptionRecords,
                    ),
                  ],
                  SizedBox(height: pad),
                  _PrescriptionTimelineSection(ongoing: ongoing, prescriptions: prescriptions),
                  SizedBox(height: pad * 0.6),
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 14),
                  QuickActionsRow(
                    actions: [
                      QuickAction(
                        label: 'Medical Records',
                        icon: Icons.folder_shared_outlined,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RecordsScreen(
                              patientId: patientId,
                              patientName: patientName,
                              prescriptions: prescriptions,
                            ),
                          ),
                        ),
                      ),
                      QuickAction(
                        label: 'Upload Report',
                        icon: Icons.upload_file_outlined,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => UploadReportScreen(patientId: patientId, patientName: patientName),
                          ),
                        ),
                      ),
                      QuickAction(
                        label: 'Emergency',
                        icon: Icons.emergency_outlined,
                        onTap: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const EmergencyHospitalsSheet(),
                        ),
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

/// The home screen's "Prescription Timeline" block — header, an optional
/// per-doctor filter (only shown once a patient actually has more than one
/// doctor prescribing to them), and up to 4 of the resulting entries with a
/// "+N more" link into the full "See all" screen. Owns the doctor-filter
/// selection itself since nothing else on the page needs it.
class _PrescriptionTimelineSection extends StatefulWidget {
  const _PrescriptionTimelineSection({required this.ongoing, required this.prescriptions});

  final List<PrescriptionTimelineEntry> ongoing;
  final List<Prescription> prescriptions;

  @override
  State<_PrescriptionTimelineSection> createState() => _PrescriptionTimelineSectionState();
}

class _PrescriptionTimelineSectionState extends State<_PrescriptionTimelineSection> {
  String? _selectedDoctor;

  List<String> get _doctorNames {
    final List<String> names = [];
    for (final PrescriptionTimelineEntry e in widget.ongoing) {
      if (e.doctorName.isNotEmpty && !names.contains(e.doctorName)) names.add(e.doctorName);
    }
    return names;
  }

  void _openSeeAll(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PrescriptionMedicinesScreen(prescriptions: widget.prescriptions)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<String> doctorNames = _doctorNames;
    // Overlap detection always looks at every doctor's medicines, even while
    // a filter is active — a duplicate involving a doctor not currently
    // selected is still worth surfacing.
    final Set<String> overlapNames = overlappingMedicineNames(widget.ongoing);
    final List<PrescriptionTimelineEntry> filtered = _selectedDoctor == null
        ? widget.ongoing
        : widget.ongoing.where((e) => e.doctorName == _selectedDoctor).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Prescription Timeline', style: theme.textTheme.titleMedium)),
            if (widget.prescriptions.isNotEmpty)
              TextButton(
                onPressed: () => _openSeeAll(context),
                style: TextButton.styleFrom(
                  foregroundColor: MColors.primaryColor,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('See all', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (widget.ongoing.isEmpty)
          Text(
            'No ongoing prescriptions right now.',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          )
        else ...[
          if (doctorNames.length > 1) ...[
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: doctorNames.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final String? doctor = index == 0 ? null : doctorNames[index - 1];
                  final bool selected = _selectedDoctor == doctor;
                  return ChoiceChip(
                    label: Text(doctor ?? 'All Doctors'),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedDoctor = doctor),
                    selectedColor: MColors.primaryColor,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : null,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    visualDensity: VisualDensity.compact,
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (filtered.isEmpty)
            Text(
              'No ongoing medicines from $_selectedDoctor.',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            )
          else ...[
            PrescriptionTimeline(entries: filtered.take(4).toList(), overlapNamesOverride: overlapNames),
            if (filtered.length > 4) ...[
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => _openSeeAll(context),
                style: TextButton.styleFrom(
                  foregroundColor: MColors.primaryColor,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  '+${filtered.length - 4} more — See all',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ],
      ],
    );
  }
}

class _MedicalInfoBanner extends StatelessWidget {
  const _MedicalInfoBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.orange.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Complete your medical profile for emergencies',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.orange),
            ],
          ),
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
