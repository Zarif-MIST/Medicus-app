import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicus/Features/Authentication/Models/auth_account.dart';
import 'package:medicus/Features/Authentication/Models/auth_role.dart';
import 'package:medicus/Features/Authentication/Services/auth_registry.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Models/doctor_appointment_model.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Models/doctor_prescription_model.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Models/patient_record_model.dart';

class DoctorService {
  DoctorService._();

  static final DoctorService instance = DoctorService._();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  Future<List<DoctorAppointmentModel>> getTodayAppointments(
    AuthAccount doctor,
  ) async {
    final DateTime now = DateTime.now();
    final DateTime startOfToday = DateTime(now.year, now.month, now.day);
    final DateTime startOfTomorrow = startOfToday.add(const Duration(days: 1));

    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctor.userId)
        .where(
          'date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday),
        )
        .where('date', isLessThan: Timestamp.fromDate(startOfTomorrow))
        .orderBy('date')
        .get();

    return [
      for (final doc in snapshot.docs)
        DoctorAppointmentModel(
          id: doc.id,
          patientId: (doc.data()['patientId'] ?? '') as String,
          patientName: (doc.data()['patientName'] ?? '') as String,
          specialty: (doc.data()['specialty'] ?? doctor.specialty ?? 'General Physician') as String,
          reason: (doc.data()['reason'] ?? '') as String,
          timeLabel: (doc.data()['time'] ?? '') as String,
          status: (doc.data()['status'] ?? 'upcoming') as String,
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

    return PatientRecordModel(
      account: account,
      bloodGroup: 'O+',
      allergies: 'Penicillin',
      chronicConditions: 'Type 2 Diabetes',
      vitals: const [
        PatientVital(label: 'Blood Pressure', value: '120/80', unit: 'mmHg'),
        PatientVital(label: 'Heart Rate', value: '76', unit: 'bpm'),
        PatientVital(label: 'Temperature', value: '98.4', unit: 'F'),
        PatientVital(label: 'Weight', value: '68', unit: 'kg'),
      ],
      history: const [
        // TODO(firebase): replace mock history with Firestore-backed patient visit history.
        PatientHistoryEntry(
          title: 'Follow-up Consultation',
          subtitle:
              'Reviewed blood sugar trends and updated medication advice.',
          dateLabel: '12 Jul 2026',
        ),
        PatientHistoryEntry(
          title: 'General Checkup',
          subtitle: 'Mild seasonal allergy symptoms noted. No urgent findings.',
          dateLabel: '28 Jun 2026',
        ),
      ],
    );
  }

  Future<List<PatientRecordModel>> searchPatients(String query) async {
    final String normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return _mockPatientRecords.values.toList();
    }

    // TODO(firebase): optimize patient search with dedicated indexes when data grows.
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'patient')
        .limit(50)
        .get();

    final List<PatientRecordModel> firestoreMatches = [];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final String userId = (data['userId'] ?? '').toString();
      final String firstName = (data['firstName'] ?? '').toString();
      final String lastName = (data['lastName'] ?? '').toString();
      final String fullName = '$firstName $lastName'.trim().toLowerCase();

      if (!userId.toLowerCase().contains(normalized) &&
          !fullName.contains(normalized)) {
        continue;
      }

      final PatientRecordModel? record = await getPatientRecordById(userId);
      if (record != null) {
        firestoreMatches.add(record);
      }
    }

    if (firestoreMatches.isNotEmpty) {
      return firestoreMatches;
    }

    return _mockPatientRecords.values
        .where((record) {
          final String fullName = record.account.fullName.toLowerCase();
          final String userId = record.account.userId.toLowerCase();
          return fullName.contains(normalized) || userId.contains(normalized);
        })
        .toList();
  }

  Future<void> savePrescription(DoctorPrescriptionModel prescription) async {
    if (prescription.diagnosis.trim().isEmpty) {
      throw ArgumentError('Diagnosis cannot be empty.');
    }

    await _firestore.collection('prescriptions').add(<String, dynamic>{
      'patientId': prescription.patientId,
      'patientName': prescription.patientName,
      'doctorId': prescription.doctorId,
      'doctorName': prescription.doctorName,
      'specialty': prescription.specialty,
      'diagnosis': prescription.diagnosis,
      'additionalNotes': prescription.additionalNotes,
      'specialtyExtras': prescription.specialtyExtras,
      'medicines': prescription.medicines
          .map(
            (medicine) => <String, dynamic>{
              'name': medicine.name,
              'dosage': medicine.dosage,
              'frequency': medicine.frequency,
              'instructions': medicine.instructions,
              'durationDays': medicine.durationDays,
              'quantity': medicine.quantity,
            },
          )
          .toList(),
      'status': 'pendingPharmacy',
      'createdAt': FieldValue.serverTimestamp(),
    });
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
      history: const <PatientHistoryEntry>[
        // TODO(firebase): replace mock history with Firestore-backed patient visit history.
        PatientHistoryEntry(
          title: 'Follow-up Consultation',
          subtitle:
              'Reviewed blood sugar trends and updated medication advice.',
          dateLabel: '12 Jul 2026',
        ),
        PatientHistoryEntry(
          title: 'General Checkup',
          subtitle: 'Mild seasonal allergy symptoms noted. No urgent findings.',
          dateLabel: '28 Jun 2026',
        ),
      ],
    );
  }
}
