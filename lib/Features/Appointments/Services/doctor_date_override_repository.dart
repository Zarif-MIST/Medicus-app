import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicus/Features/Appointments/Models/doctor_date_override.dart';

/// A doctor's Service Planner calendar overrides — single equality filter on
/// `doctorId`, same convention as the rest of this app's reads. Each date has
/// at most one override, keyed by a deterministic doc ID so setting one is a
/// plain upsert rather than a query-then-write.
class DoctorDateOverrideRepository {
  const DoctorDateOverrideRepository();

  CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance.collection('doctor_date_overrides');

  Future<List<DoctorDateOverride>> fetchForDoctor(String doctorId) async {
    if (doctorId.isEmpty) return const [];
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _collection
        .where('doctorId', isEqualTo: doctorId)
        .get();
    return snapshot.docs.map(DoctorDateOverride.fromDoc).toList();
  }

  Future<void> setStatus({
    required String doctorId,
    required DateTime date,
    required DoctorDateStatus status,
  }) async {
    final DoctorDateOverride override = DoctorDateOverride(
      doctorId: doctorId,
      date: date,
      status: status,
    );
    await _collection
        .doc(DoctorDateOverride.docIdFor(doctorId, date))
        .set(override.toJson());
  }

  Future<void> clear({required String doctorId, required DateTime date}) {
    return _collection
        .doc(DoctorDateOverride.docIdFor(doctorId, date))
        .delete();
  }
}
