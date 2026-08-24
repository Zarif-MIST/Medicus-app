import 'package:medicus/Features/Appointments/Models/appointment_record.dart';
import 'package:medicus/Features/Appointments/Services/appointment_repository.dart';
import 'package:medicus/Features/Authentication/Models/auth_account.dart';
import 'package:medicus/Features/Authentication/Models/auth_role.dart';
import 'package:medicus/Features/Authentication/Services/auth_registry.dart';
import 'package:medicus/Features/Prescriptions/Models/prescription_record.dart';
import 'package:medicus/Features/Prescriptions/Services/prescription_repository.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Models/doctor_appointment_model.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Models/doctor_prescription_model.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Models/patient_record_model.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Utilities/patient_profile_service.dart';

class DoctorService {
  DoctorService._();

  static final DoctorService instance = DoctorService._();

  static final Map<String, PatientRecordModel> _mockPatientRecords =
      <String, PatientRecordModel>{
        '4821': _buildMockPatientRecord(
          userId: '4821',
          firstName: 'Tareq',
          lastName: 'Hasan',
          email: 'tareq@example.com',
          phoneNumber: '+8801711000001',
          bloodGroup: 'O+',
          allergies: 'Penicillin',
          chronicConditions: 'Type 2 Diabetes',
        ),
        '5634': _buildMockPatientRecord(
          userId: '5634',
          firstName: 'Sadia',
          lastName: 'Rahman',
          email: 'sadia@example.com',
          phoneNumber: '+8801711000002',
          bloodGroup: 'A+',
          allergies: 'Dust',
          chronicConditions: 'Seasonal sinusitis',
        ),
        '6108': _buildMockPatientRecord(
          userId: '6108',
          firstName: 'Nafis',
          lastName: 'Ahmed',
          email: 'nafis@example.com',
          phoneNumber: '+8801711000003',
          bloodGroup: 'B+',
          allergies: 'None reported',
          chronicConditions: 'Mild hypertension',
        ),
      };

  static const AppointmentRepository _appointmentRepository = AppointmentRepository();

  Future<List<DoctorAppointmentModel>> getTodayAppointments(
    AuthAccount doctor,
  ) async {
    if (doctor.userId.isEmpty) return const [];

    final List<AppointmentRecord> records = await _appointmentRepository.fetchForDoctor(doctor.userId);
    final DateTime now = DateTime.now();
    final List<AppointmentRecord> today = records
        .where((r) => r.date.year == now.year && r.date.month == now.month && r.date.day == now.day)
        .toList();

    return [
      for (final record in today)
        DoctorAppointmentModel(
          id: record.id,
          patientId: record.patientId,
          patientName: record.patientName,
          specialty: record.specialty,
          reason: 'Booked via Medicus',
          timeLabel: record.time,
          status: record.status,
        ),
    ];
  }

  Future<PatientRecordModel?> getPatientRecordById(String patientId) async {
    final String normalizedId = patientId.trim();
    if (normalizedId.isEmpty) {
      return null;
    }

    final AuthAccount? account = await AuthRegistry.instance.accountForUserId(
      normalizedId,
    );
    if (account == null || account.role != AuthRole.patient) {
      return _mockPatientRecords[normalizedId];
    }

    const PatientProfileService profileService = PatientProfileService();
    final PatientProfileRecord? profile = await profileService.fetch(normalizedId);

    return PatientRecordModel(
      account: account,
      bloodGroup: (profile?.bloodGroup.trim().isNotEmpty ?? false) ? profile!.bloodGroup : 'Not set',
      allergies: (profile?.allergies.trim().isNotEmpty ?? false) ? profile!.allergies : 'Not set',
      chronicConditions:
          (profile?.chronicConditions.trim().isNotEmpty ?? false) ? profile!.chronicConditions : 'Not set',
      // TODO(firebase): no vitals-recording feature exists yet — these stay
      // as honest placeholders rather than fabricated numbers once one does.
      vitals: const [
        PatientVital(label: 'Blood Pressure', value: '—', unit: ''),
        PatientVital(label: 'Heart Rate', value: '—', unit: ''),
        PatientVital(label: 'Temperature', value: '—', unit: ''),
        PatientVital(label: 'Weight', value: '—', unit: ''),
      ],
    );
  }

  static const PrescriptionRepository _prescriptionRepository = PrescriptionRepository();

  Future<String> savePrescription(DoctorPrescriptionModel prescription) async {
    if (prescription.diagnosis.trim().isEmpty) {
      throw ArgumentError('Diagnosis cannot be empty.');
    }
    if (prescription.medicines.isEmpty) {
      throw ArgumentError('Add at least one medicine.');
    }

    return _prescriptionRepository.create(
      patientId: prescription.patientId,
      patientName: prescription.patientName,
      doctorId: prescription.doctorId,
      doctorName: prescription.doctorName,
      specialty: prescription.specialty,
      diagnosis: prescription.diagnosis,
      additionalNotes: prescription.additionalNotes,
      medicines: [
        for (final medicine in prescription.medicines)
          PrescriptionRecordMedicine(
            name: medicine.name,
            dosage: medicine.dosage,
            instructions: medicine.instructions,
            durationDays: medicine.durationDays,
            doseTimes: medicine.doseTimes,
          ),
      ],
    );
  }

  static PatientRecordModel _buildMockPatientRecord({
    required String userId,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String bloodGroup,
    required String allergies,
    required String chronicConditions,
  }) {
    return PatientRecordModel(
      account: AuthAccount(
        userId: userId,
        role: AuthRole.patient,
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: '',
        phoneNumber: phoneNumber,
        verificationCode: '',
        isVerified: true,
      ),
      bloodGroup: bloodGroup,
      allergies: allergies,
      chronicConditions: chronicConditions,
      vitals: const <PatientVital>[
        PatientVital(label: 'Blood Pressure', value: '120/80', unit: 'mmHg'),
        PatientVital(label: 'Heart Rate', value: '76', unit: 'bpm'),
        PatientVital(label: 'Temperature', value: '98.4', unit: 'F'),
        PatientVital(label: 'Weight', value: '68', unit: 'kg'),
      ],
    );
  }
}
