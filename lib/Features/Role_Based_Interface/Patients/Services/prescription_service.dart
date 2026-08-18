import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/records/prescription.dart';

class PrescriptionService {
  PrescriptionService._();

  static final PrescriptionService instance = PrescriptionService._();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Prescription>> getPrescriptionsForPatient(
    String patientId,
  ) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('prescriptions')
        .where('patientId', isEqualTo: patientId)
        .orderBy('createdAt', descending: true)
        .get();

    return [
      for (final doc in snapshot.docs) _fromFirestore(doc.id, doc.data()),
    ];
  }

  Prescription _fromFirestore(String id, Map<String, dynamic> data) {
    final Timestamp? createdAt = data['createdAt'] as Timestamp?;
    final List<dynamic> rawMedicines =
        (data['medicines'] as List<dynamic>?) ?? const <dynamic>[];

    return Prescription(
      id: id,
      doctorName: (data['doctorName'] ?? '') as String,
      date: createdAt?.toDate() ?? DateTime.now(),
      medicines: [
        for (final rawMedicine in rawMedicines)
          PrescriptionMedicine(
            name: (rawMedicine['name'] ?? '') as String,
            dosage: (rawMedicine['dosage'] ?? '') as String,
            durationDays: (rawMedicine['durationDays'] as num?)?.toInt() ?? 0,
          ),
      ],
    );
  }
}
