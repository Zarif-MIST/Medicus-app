import 'package:flutter/material.dart';
import 'package:medicus/Features/Appointments/Models/appointment_record.dart';
import 'package:medicus/Features/Appointments/Services/appointment_repository.dart';
import 'package:medicus/Features/Authentication/Models/auth_account.dart';
import 'package:medicus/Features/Prescriptions/Models/prescription_record.dart';
import 'package:medicus/Features/Prescriptions/Services/prescription_repository.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Widgets/LiquidNavbar.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Screens/home/patient_home_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Screens/doctors/specialist_selection_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Screens/pharmacies/pharmacy_locator_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Screens/profile/patient_profile_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Utilities/patient_profile_service.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/doctors/booked_appointment.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/records/prescription.dart';

// TODO: replace with the logged-in patient's real userId once every screen
// consistently receives a fully-populated AuthAccount — matches the mock id
// used app-wide (pharmacy, lab reports, doctor's mock patient lookup).
const String _mockPatientId = '4821';
const String _mockPatientName = 'Tareq';

class PatientDashboardScreen extends StatelessWidget {
  const PatientDashboardScreen({super.key, required this.account});

  final AuthAccount account;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _PatientHomeShell(account: account));
  }
}

class _PatientHomeShell extends StatefulWidget {
  const _PatientHomeShell({required this.account});

  final AuthAccount account;

  @override
  State<_PatientHomeShell> createState() => _PatientHomeShellState();
}

class _PatientHomeShellState extends State<_PatientHomeShell> {
  static const PrescriptionRepository _prescriptionRepository =
      PrescriptionRepository();
  static const AppointmentRepository _appointmentRepository =
      AppointmentRepository();
  static const PatientProfileService _profileService = PatientProfileService();

  int _index = 0;
  List<BookedAppointment> _appointments = [];
  List<Prescription> _prescriptions = [];
  List<PrescriptionRecord> _prescriptionRecords = [];
  bool _medicalInfoIncomplete = false;

  String get _patientId =>
      widget.account.userId.isEmpty ? _mockPatientId : widget.account.userId;
  String get _patientName => widget.account.firstName.isEmpty
      ? _mockPatientName
      : widget.account.fullName;

  final _items = const [
    LiquidNavItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Home',
    ),
    LiquidNavItem(
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
      label: 'Appointment',
    ),
    LiquidNavItem(
      icon: Icons.local_pharmacy_outlined,
      selectedIcon: Icons.local_pharmacy,
      label: 'Pharmacies',
    ),
    LiquidNavItem(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: 'Profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
    _loadAppointments();
    _loadProfileStatus();
  }

  Future<void> _loadProfileStatus() async {
    try {
      final PatientProfileRecord? record = await _profileService.fetch(
        _patientId,
      );
      if (!mounted) return;
      setState(
        () => _medicalInfoIncomplete =
            record == null || !record.medicalInfoCompleted,
      );
    } catch (_) {
      // Leave the banner hidden on failure (e.g. offline) rather than
      // guessing — it'll re-check next time the dashboard opens.
    }
  }

  Future<void> _loadPrescriptions() async {
    try {
      final List<PrescriptionRecord> records = await _prescriptionRepository
          .fetchForPatient(_patientId);
      if (!mounted) return;
      setState(() {
        _prescriptionRecords = records;
        _prescriptions = [
          for (final record in records) _toPrescription(record),
        ];
      });
    } catch (_) {
      // Leave the list empty on failure (e.g. offline) — every screen
      // downstream already renders a graceful "no prescriptions" state.
    }
  }

  Future<void> _loadAppointments() async {
    try {
      final List<AppointmentRecord> records = await _appointmentRepository
          .fetchForPatient(_patientId);
      if (!mounted) return;
      final List<BookedAppointment> fetched = [
        for (final record in records) _toBookedAppointment(record),
      ];

      // An optimistic booking (id.isEmpty — added locally in _addAppointment
      // before its Firestore write confirmed) can still be mid-flight when
      // this reload runs, e.g. right after the confirmation dialog if the
      // patient immediately switches back to the Home tab. Replacing
      // _appointments outright would wipe it until the *next* reload. Keep
      // any such pending entries that don't yet have a matching real record
      // in the fresh fetch; drop them once the fetch shows the real one.
      final List<BookedAppointment> stillPending = _appointments.where((a) {
        if (a.id.isNotEmpty) return false;
        final bool nowConfirmed = fetched.any(
          (f) =>
              f.doctorId == a.doctorId &&
              f.windowId == a.windowId &&
              f.date.year == a.date.year &&
              f.date.month == a.date.month &&
              f.date.day == a.date.day &&
              f.time == a.time,
        );
        return !nowConfirmed;
      }).toList();

      setState(() => _appointments = [...fetched, ...stillPending]);
    } catch (_) {
      // Leave the list as-is on failure — the calendar/next-appointment
      // widgets already render a graceful "no appointments" state when empty.
    }
  }

  BookedAppointment _toBookedAppointment(AppointmentRecord record) {
    return BookedAppointment(
      id: record.id,
      doctorId: record.doctorId,
      doctorName: record.doctorName,
      specialty: record.specialty,
      hospital: record.hospital,
      date: record.date,
      time: record.time,
      fee: record.fee,
      windowId: record.windowId,
    );
  }

  Prescription _toPrescription(PrescriptionRecord record) {
    return Prescription(
      id: record.id,
      doctorName: record.doctorName,
      date: record.createdAt,
      medicines: [
        for (final medicine in record.medicines)
          PrescriptionMedicine(
            name: medicine.name,
            dosage: medicine.instructions.isEmpty
                ? medicine.dosage
                : '${medicine.dosage} — ${medicine.instructions}',
            durationDays: medicine.durationDays,
          ),
      ],
    );
  }

  Future<void> _addAppointment(BookedAppointment appointment) async {
    setState(() => _appointments = [..._appointments, appointment]);
    try {
      await _appointmentRepository.create(
        patientId: _patientId,
        patientName: _patientName,
        doctorId: appointment.doctorId,
        doctorName: appointment.doctorName,
        specialty: appointment.specialty,
        hospital: appointment.hospital,
        date: appointment.date,
        time: appointment.time,
        fee: appointment.fee,
        windowId: appointment.windowId,
      );
    } catch (_) {
      // Booking still shows locally for this session even if the write
      // failed (e.g. offline) — _loadAppointments will reconcile with
      // Firestore next time the dashboard is reopened.
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      PatientHomeScreen(
        account: widget.account,
        appointments: _appointments,
        prescriptions: _prescriptions,
        prescriptionRecords: _prescriptionRecords,
        onBookAppointment: _addAppointment,
        medicalInfoIncomplete: _medicalInfoIncomplete,
        onCompleteMedicalInfo: () => setState(() => _index = 3),
      ),
      SpecialistSelectionScreen(
        appointments: _appointments,
        onBook: _addAppointment,
      ),
      PharmacyLocatorScreen(account: widget.account),
      PatientProfileScreen(
        account: widget.account,
        prescriptions: _prescriptions,
      ),
    ];

    return Scaffold(
      // extendBody lets page content flow behind the nav bar so the
      // BackdropFilter actually has something colorful to blur.
      extendBody: true,
      body: Stack(
        children: [
          pages[_index],
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: LiquidGlassNavBar(
              items: _items,
              selectedIndex: _index,
              onTap: (i) {
                setState(() => _index = i);
                if (i == 0) {
                  _loadProfileStatus();
                  _loadPrescriptions();
                  _loadAppointments();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
