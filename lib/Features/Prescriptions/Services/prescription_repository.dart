import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicus/Features/Prescriptions/Models/prescription_record.dart';

/// Thrown when a scanned/looked-up prescription id doesn't exist on file.
class PrescriptionNotFoundException implements Exception {
  const PrescriptionNotFoundException(this.rxId);
  final String rxId;

  @override
  String toString() => 'No prescription found for id "$rxId".';
}

/// Thrown when a scanned QR's embedded patient details don't match the live
/// Firestore record for that prescription id — the QR is a convenience
/// cache, the Firestore document is the source of truth, so a mismatch is
/// treated as a verification failure rather than silently trusted.
class PrescriptionVerificationException implements Exception {
  const PrescriptionVerificationException(this.rxId);
  final String rxId;

  @override
  String toString() => 'Prescription $rxId did not match the record on file.';
}

/// The single Firestore collection ('prescriptions') behind the whole
/// doctor-writes / patient-reads / pharmacist-verifies-and-dispenses loop.
class PrescriptionRepository {
  const PrescriptionRepository();

  CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance.collection('prescriptions');

  Future<String> create({
    required String patientId,
    required String patientName,
    required String doctorId,
    required String doctorName,
    required String specialty,
    required String diagnosis,
    required String additionalNotes,
    required List<PrescriptionRecordMedicine> medicines,
  }) async {
    final PrescriptionRecord draft = PrescriptionRecord(
      id: '',
      patientId: patientId,
      patientName: patientName,
      doctorId: doctorId,
      doctorName: doctorName,
      specialty: specialty,
      diagnosis: diagnosis,
      additionalNotes: additionalNotes,
      medicines: medicines,
      status: PrescriptionRecord.statusPending,
      createdAt: DateTime.now(),
    );

    final DocumentReference<Map<String, dynamic>> ref = await _collection.add(draft.toCreateJson());
    return ref.id;
  }

  Future<List<PrescriptionRecord>> fetchForPatient(String patientId) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _collection.where('patientId', isEqualTo: patientId).get();

    final List<PrescriptionRecord> records = snapshot.docs.map(PrescriptionRecord.fromDoc).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return records;
  }

  Future<List<PrescriptionRecord>> fetchByStatus(String status) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _collection.where('status', isEqualTo: status).get();

    final List<PrescriptionRecord> records = snapshot.docs.map(PrescriptionRecord.fromDoc).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return records;
  }

  Future<PrescriptionRecord?> fetchById(String id) async {
    final DocumentSnapshot<Map<String, dynamic>> doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return PrescriptionRecord.fromDoc(doc);
  }

  /// Looks the prescription up by id and cross-checks the patient identity
  /// embedded in the scanned QR against the live record. Throws
  /// [PrescriptionNotFoundException] or [PrescriptionVerificationException]
  /// rather than returning something the caller might mistake for verified.
  Future<PrescriptionRecord> verifyScan({required String rxId, required String patientId}) async {
    final PrescriptionRecord? record = await fetchById(rxId);
    if (record == null) {
      throw PrescriptionNotFoundException(rxId);
    }
    if (patientId.isNotEmpty && record.patientId != patientId) {
      throw PrescriptionVerificationException(rxId);
    }
    return record;
  }

  Future<void> markDispensed(String id) async {
    final DocumentSnapshot<Map<String, dynamic>> doc = await _collection.doc(id).get();
    if (!doc.exists) {
      throw PrescriptionNotFoundException(id);
    }

    await _collection.doc(id).update({
      'status': PrescriptionRecord.statusDispensed,
      'dispensedAt': FieldValue.serverTimestamp(),
    });
  }
}
