import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:medicus/Features/Appointments/Models/doctor_availability_window.dart';
import 'package:medicus/Features/Appointments/Services/appointment_repository.dart';
import 'package:medicus/Features/Appointments/Services/doctor_availability_repository.dart';
import 'package:medicus/Features/Authentication/Models/auth_account.dart';
import 'package:medicus/Features/Authentication/Models/auth_role.dart';
import 'package:medicus/Features/Authentication/Services/auth_registry.dart';
import 'package:medicus/Features/Prescriptions/Models/prescription_record.dart';
import 'package:medicus/Features/Prescriptions/Models/scheduled_dose.dart';
import 'package:medicus/Features/Prescriptions/Services/dose_log_repository.dart';
import 'package:medicus/Features/Prescriptions/Services/prescription_repository.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Utilities/lab_report_service.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Utilities/patient_profile_service.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Utilities/pharmacy_review_service.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Utilities/pharmacy_visit_service.dart';
import 'package:medicus/Utilities/colors.dart';

/// Debug-only tool to populate Firestore with realistic supporting data
/// (prescriptions, appointments, availability windows, profile info,
/// pharmacy visit/review, dose history, a lab report) against three
/// already-registered accounts, so the whole patient feature set can be
/// tested end-to-end without going through registration/email verification
/// again. Never touches Firebase Auth, registration, or login.
class PatientTestDataSeederScreen extends StatefulWidget {
  const PatientTestDataSeederScreen({super.key});

  @override
  State<PatientTestDataSeederScreen> createState() =>
      _PatientTestDataSeederScreenState();
}

class _PatientTestDataSeederScreenState
    extends State<PatientTestDataSeederScreen> {
  final TextEditingController _doctorIdController = TextEditingController();
  final TextEditingController _pharmacistIdController = TextEditingController();
  final TextEditingController _patientIdController = TextEditingController();

  AuthAccount? _doctor;
  AuthAccount? _pharmacist;
  AuthAccount? _patient;
  bool _loadingAccounts = false;
  final List<String> _log = [];

  bool get _ready => _doctor != null && _pharmacist != null && _patient != null;

  @override
  void dispose() {
    _doctorIdController.dispose();
    _pharmacistIdController.dispose();
    _patientIdController.dispose();
    super.dispose();
  }

  void _appendLog(String message) {
    if (!mounted) return;
    setState(() => _log.insert(0, message));
  }

  String get _doctorDisplayName {
    final String name = _doctor!.fullName.trim();
    if (name.isEmpty) return 'Dr. Unnamed';
    return name.toLowerCase().startsWith('dr') ? name : 'Dr. $name';
  }

  Future<void> _loadAccounts() async {
    setState(() => _loadingAccounts = true);
    final AuthAccount? doctor = await AuthRegistry.instance.accountForUserId(
      _doctorIdController.text.trim(),
    );
    final AuthAccount? pharmacist = await AuthRegistry.instance
        .accountForUserId(_pharmacistIdController.text.trim());
    final AuthAccount? patient = await AuthRegistry.instance.accountForUserId(
      _patientIdController.text.trim(),
    );

    setState(() {
      _doctor = (doctor != null && doctor.role == AuthRole.doctor)
          ? doctor
          : null;
      _pharmacist =
          (pharmacist != null && pharmacist.role == AuthRole.pharmacist)
          ? pharmacist
          : null;
      _patient = (patient != null && patient.role == AuthRole.patient)
          ? patient
          : null;
      _loadingAccounts = false;
    });

    _appendLog(
      'Doctor: ${_doctor == null ? "not found / wrong role" : "${_doctor!.fullName} (${_doctor!.userId})"}',
    );
    _appendLog(
      'Pharmacist: ${_pharmacist == null ? "not found / wrong role" : "${_pharmacist!.fullName} (${_pharmacist!.userId})"}',
    );
    _appendLog(
      'Patient: ${_patient == null ? "not found / wrong role" : "${_patient!.fullName} (${_patient!.userId})"}',
    );
  }

  Future<void> _seedAvailability() async {
    try {
      const DoctorAvailabilityRepository repo = DoctorAvailabilityRepository();
      final int today = DateTime.now().weekday;
      final int otherDay = today == DateTime.monday
          ? DateTime.wednesday
          : DateTime.monday;

      await repo.create(
        doctorId: _doctor!.userId,
        weekday: today,
        startTime: '16:00',
        endTime: '18:00',
        capacity: 5,
      );
      await repo.create(
        doctorId: _doctor!.userId,
        weekday: otherDay,
        startTime: '10:00',
        endTime: '12:00',
        capacity: 20,
      );

      _appendLog(
        'Availability: created ${kWeekdayFullNames[today - 1]} 4-6 PM (cap 5) + ${kWeekdayFullNames[otherDay - 1]} 10-12 (cap 20)',
      );
    } catch (e) {
      _appendLog('Availability: failed - $e');
    }
  }

  Future<void> _seedPrescriptions() async {
    try {
      const PrescriptionRepository repo = PrescriptionRepository();

      await repo.create(
        patientId: _patient!.userId,
        patientName: _patient!.fullName,
        doctorId: _doctor!.userId,
        doctorName: _doctorDisplayName,
        specialty: _doctor!.specialty ?? '',
        diagnosis: 'Acute gastritis with fever',
        additionalNotes:
            'Seed test data — follow up in 1 week if symptoms persist.',
        medicines: const [
          PrescriptionRecordMedicine(
            name: 'Napa 500mg',
            dosage: '1 tablet after meals',
            instructions: 'Take with food',
            durationDays: 7,
            doseTimes: ['08:00', '20:00'],
          ),
          PrescriptionRecordMedicine(
            name: 'Seclo 20mg',
            dosage: '1 tablet before breakfast',
            instructions: 'Take on an empty stomach',
            durationDays: 5,
            doseTimes: ['07:30'],
          ),
        ],
      );

      await repo.create(
        patientId: _patient!.userId,
        patientName: _patient!.fullName,
        doctorId: _doctor!.userId,
        doctorName: _doctorDisplayName,
        specialty: _doctor!.specialty ?? '',
        diagnosis: 'Type 2 Diabetes follow-up',
        additionalNotes: 'Seed test data — continue monitoring blood sugar.',
        medicines: const [
          PrescriptionRecordMedicine(
            name: 'Metformin 500mg',
            dosage: '1 tablet twice daily',
            instructions: 'Take after meals',
            durationDays: 30,
            doseTimes: ['09:00', '21:00'],
          ),
        ],
      );

      _appendLog('Prescriptions: created 2 (gastritis + diabetes follow-up)');
    } catch (e) {
      _appendLog('Prescriptions: failed - $e');
    }
  }

  Future<DoctorAvailabilityWindow?> _todaysWindow() async {
    const DoctorAvailabilityRepository repo = DoctorAvailabilityRepository();
    final List<DoctorAvailabilityWindow> windows = await repo.fetchForDoctor(
      _doctor!.userId,
    );
    if (windows.isEmpty) return null;
    final int today = DateTime.now().weekday;
    return windows.firstWhere(
      (w) => w.weekday == today,
      orElse: () => windows.first,
    );
  }

  Future<void> _seedAppointment() async {
    try {
      final DoctorAvailabilityWindow? window = await _todaysWindow();
      if (window == null) {
        _appendLog('Appointment: failed - seed Doctor Availability first');
        return;
      }

      const AppointmentRepository appointmentRepo = AppointmentRepository();
      await appointmentRepo.create(
        patientId: _patient!.userId,
        patientName: _patient!.fullName,
        doctorId: _doctor!.userId,
        doctorName: _doctorDisplayName,
        specialty: _doctor!.specialty ?? '',
        hospital: '',
        date: DateTime.now(),
        time: window.label,
        fee: 800,
        windowId: window.id,
      );

      _appendLog(
        'Appointment: booked patient into ${window.weekdayName} ${window.label}',
      );
    } catch (e) {
      _appendLog('Appointment: failed - $e');
    }
  }

  Future<void> _fillWindowToCapacity() async {
    try {
      final DoctorAvailabilityWindow? window = await _todaysWindow();
      if (window == null) {
        _appendLog('Fill to Capacity: failed - seed Doctor Availability first');
        return;
      }

      const AppointmentRepository appointmentRepo = AppointmentRepository();
      final int already = await appointmentRepo.countBookingsForWindow(
        doctorId: _doctor!.userId,
        windowId: window.id,
        date: DateTime.now(),
      );
      final int toCreate = (window.capacity - already).clamp(
        0,
        window.capacity,
      );

      for (int i = 0; i < toCreate; i++) {
        await appointmentRepo.create(
          patientId: 'seed-filler-$i',
          patientName: 'Test Patient ${i + 2}',
          doctorId: _doctor!.userId,
          doctorName: _doctorDisplayName,
          specialty: _doctor!.specialty ?? '',
          hospital: '',
          date: DateTime.now(),
          time: window.label,
          fee: 800,
          windowId: window.id,
        );
      }

      _appendLog(
        'Fill to Capacity: added $toCreate filler booking(s) — window should now show Full',
      );
    } catch (e) {
      _appendLog('Fill to Capacity: failed - $e');
    }
  }

  Future<void> _seedProfile() async {
    try {
      const PatientProfileService service = PatientProfileService();
      await service.save(
        PatientProfileRecord(
          patientId: _patient!.userId,
          phone: _patient!.phoneNumber,
          email: _patient!.email,
          address: 'Dhanmondi, Dhaka',
          dateOfBirth: '12 Mar 1998',
          bloodGroup: 'O+',
          allergies: 'Penicillin',
          chronicConditions: 'Type 2 Diabetes',
          emergencyContactName: 'Rafiq Hasan (Brother)',
          emergencyContactPhone: '+8801700000000',
          medicalInfoCompleted: true,
        ),
      );
      _appendLog('Profile: seeded complete personal/medical/emergency info');
    } catch (e) {
      _appendLog('Profile: failed - $e');
    }
  }

  Future<void> _resetProfile() async {
    try {
      await FirebaseFirestore.instance
          .collection('patient_profiles')
          .doc(_patient!.userId)
          .delete();
      _appendLog(
        'Profile: deleted (simulates a fresh signup — onboarding will show on next login)',
      );
    } catch (e) {
      _appendLog('Profile reset: failed - $e');
    }
  }

  Future<void> _seedDoseLogs() async {
    try {
      const PrescriptionRepository prescriptionRepo = PrescriptionRepository();
      const DoseLogRepository doseLogRepo = DoseLogRepository();

      final List<PrescriptionRecord> prescriptions = await prescriptionRepo
          .fetchForPatient(_patient!.userId);
      if (prescriptions.isEmpty) {
        _appendLog('Dose Logs: failed - seed Prescriptions first');
        return;
      }

      final DateTime now = DateTime.now();
      final List<ScheduledDose> doses = expandDoseSchedule(
        prescriptions: prescriptions,
        rangeStart: now.subtract(const Duration(days: 2)),
        rangeEnd: now,
      );
      final List<ScheduledDose> past = doses
          .where((d) => d.scheduledAt.isBefore(now))
          .toList();

      int marked = 0;
      for (int i = 0; i < past.length; i++) {
        if (i.isEven) {
          await doseLogRepo.markTaken(
            patientId: _patient!.userId,
            dose: past[i],
          );
          marked++;
        }
      }

      _appendLog(
        'Dose Logs: marked $marked of ${past.length} past scheduled doses as taken',
      );
    } catch (e) {
      _appendLog('Dose Logs: failed - $e');
    }
  }

  Future<void> _seedPharmacyVisit() async {
    try {
      final String? pharmacyId = _pharmacist!.firebaseUid;
      if (pharmacyId == null) {
        _appendLog('Pharmacy: failed - pharmacist account has no firebaseUid');
        return;
      }

      const PharmacyVisitService visitService = PharmacyVisitService();
      const PharmacyReviewService reviewService = PharmacyReviewService();

      await visitService.markVisited(
        patientId: _patient!.userId,
        pharmacyId: pharmacyId,
      );
      await reviewService.submitReview(
        pharmacyId: pharmacyId,
        patientId: _patient!.userId,
        patientName: _patient!.fullName,
        rating: 5,
        comment: 'Quick service, friendly staff. (seed test data)',
      );

      _appendLog('Pharmacy: marked visited + submitted a 5-star review');
    } catch (e) {
      _appendLog('Pharmacy: failed - $e');
    }
  }

  Future<void> _seedLabReport() async {
    try {
      final img.Image placeholder = img.Image(width: 400, height: 300);
      img.fill(placeholder, color: img.ColorRgb8(226, 232, 240));
      final Uint8List bytes = Uint8List.fromList(
        img.encodeJpg(placeholder, quality: 70),
      );

      const LabReportService service = LabReportService();
      await service.upload(
        patientId: _patient!.userId,
        patientName: _patient!.fullName,
        label: 'CBC Report (seed)',
        imageBytes: bytes,
      );

      _appendLog('Lab Report: uploaded a placeholder report');
    } catch (e) {
      _appendLog('Lab Report: failed - $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seed Test Data (Debug)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter the 4-digit userId of accounts already registered through the app, then load them before seeding.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _doctorIdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Doctor userId',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _pharmacistIdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Pharmacist userId',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _patientIdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Patient userId',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loadingAccounts ? null : _loadAccounts,
              style: ElevatedButton.styleFrom(
                backgroundColor: MColors.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text(_loadingAccounts ? 'Loading…' : 'Load Accounts'),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SeedButton(
                  label: 'Doctor Availability',
                  enabled: _ready,
                  onPressed: _seedAvailability,
                ),
                _SeedButton(
                  label: 'Prescriptions',
                  enabled: _ready,
                  onPressed: _seedPrescriptions,
                ),
                _SeedButton(
                  label: 'Appointment',
                  enabled: _ready,
                  onPressed: _seedAppointment,
                ),
                _SeedButton(
                  label: 'Fill Window to Capacity',
                  enabled: _ready,
                  onPressed: _fillWindowToCapacity,
                ),
                _SeedButton(
                  label: 'Patient Profile',
                  enabled: _ready,
                  onPressed: _seedProfile,
                ),
                _SeedButton(
                  label: 'Reset Profile',
                  enabled: _ready,
                  onPressed: _resetProfile,
                ),
                _SeedButton(
                  label: 'Dose Logs',
                  enabled: _ready,
                  onPressed: _seedDoseLogs,
                ),
                _SeedButton(
                  label: 'Pharmacy Visit + Review',
                  enabled: _ready,
                  onPressed: _seedPharmacyVisit,
                ),
                _SeedButton(
                  label: 'Lab Report',
                  enabled: _ready,
                  onPressed: _seedLabReport,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _log.length,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    _log[i],
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeedButton extends StatefulWidget {
  const _SeedButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final Future<void> Function() onPressed;

  @override
  State<_SeedButton> createState() => _SeedButtonState();
}

class _SeedButtonState extends State<_SeedButton> {
  bool _busy = false;

  Future<void> _handleTap() async {
    setState(() => _busy = true);
    await widget.onPressed();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: (widget.enabled && !_busy) ? _handleTap : null,
      child: _busy
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(widget.label),
    );
  }
}
