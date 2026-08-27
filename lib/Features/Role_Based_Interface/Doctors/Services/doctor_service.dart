import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicus/Features/Authentication/Models/auth_account.dart';
import 'package:medicus/Features/Authentication/Models/auth_role.dart';
import 'package:medicus/Features/Authentication/Services/auth_registry.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Models/doctor_appointment_model.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Models/doctor_prescription_model.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Models/patient_lab_result_model.dart';
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

    // Single equality filter on doctorId only — combining it with a date
    // range + orderBy would need a composite Firestore index that isn't
    // provisioned for this project, so the today-window is filtered/sorted
    // client-side on the (small) per-doctor result set instead.
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctor.userId)
        .get();

    final List<DoctorAppointmentModel> todaysAppointments = [
      for (final doc in snapshot.docs)
        if (_isWithin(doc.data()['date'], startOfToday, startOfTomorrow))
          DoctorAppointmentModel(
            id: doc.id,
            patientId: (doc.data()['patientId'] ?? '') as String,
            patientName: (doc.data()['patientName'] ?? '') as String,
            specialty:
                (doc.data()['specialty'] ??
                        doctor.specialty ??
                        'General Physician')
                    as String,
            reason: (doc.data()['reason'] ?? '') as String,
            timeLabel: (doc.data()['time'] ?? '') as String,
            status: (doc.data()['status'] ?? 'upcoming') as String,
          ),
    ];
    todaysAppointments.sort((a, b) => a.timeLabel.compareTo(b.timeLabel));
    return todaysAppointments;
  }

  bool _isWithin(Object? rawDate, DateTime start, DateTime endExclusive) {
    if (rawDate is! Timestamp) {
      return false;
    }
    final DateTime date = rawDate.toDate();
    return !date.isBefore(start) && date.isBefore(endExclusive);
  }

  /// IDs of patients this doctor has already written a prescription for
  /// today — used to derive "Patients Seen" / "Pending Cases" stats.
  Future<Set<String>> getPatientsSeenTodayIds(String doctorId) async {
    final DateTime now = DateTime.now();
    final DateTime startOfToday = DateTime(now.year, now.month, now.day);

    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('prescriptions')
        .where('doctorId', isEqualTo: doctorId)
        .get();

    final Set<String> patientIds = <String>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final Timestamp? createdAt = data['createdAt'] as Timestamp?;
      if (createdAt == null || createdAt.toDate().isBefore(startOfToday)) {
        continue;
      }
      final String patientId = (data['patientId'] ?? '') as String;
      if (patientId.isNotEmpty) {
        patientIds.add(patientId);
      }
    }
    return patientIds;
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

    return _mockPatientRecords.values.where((record) {
      final String fullName = record.account.fullName.toLowerCase();
      final String userId = record.account.userId.toLowerCase();
      return fullName.contains(normalized) || userId.contains(normalized);
    }).toList();
  }

  /// Completed lab orders for one patient, newest first — reads the same
  /// `lab_orders` collection the lab specialist's Results screen writes to,
  /// so a result attached there is immediately visible here.
  Future<List<PatientLabResultModel>> getLabResultsForPatient(
    String patientId,
  ) async {
    final String id = patientId.trim();
    if (id.isEmpty) {
      return const [];
    }

    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('lab_orders')
        .where('status', isEqualTo: 'Completed')
        .where('patientId', isEqualTo: id)
        .get();

    final List<PatientLabResultModel> results = [
      for (final doc in snapshot.docs)
        _labResultFromFirestore(doc.id, doc.data()),
    ];
    results.sort((a, b) {
      final DateTime aTime =
          a.completedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime bTime =
          b.completedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return results;
  }

  PatientLabResultModel _labResultFromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final Object? rawCompletedAt = data['completedAt'];
    return PatientLabResultModel(
      id: id,
      orderType: (data['orderType'] ?? '').toString(),
      requestedBy: (data['requestedBy'] ?? '').toString(),
      resultNote: data['resultNote'] as String?,
      resultFileName: data['resultFileName'] as String?,
      completedAt: rawCompletedAt is Timestamp ? rawCompletedAt.toDate() : null,
    );
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
