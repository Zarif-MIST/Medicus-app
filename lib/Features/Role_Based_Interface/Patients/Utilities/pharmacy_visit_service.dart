import 'package:cloud_firestore/cloud_firestore.dart';

/// Tracks which pharmacies a patient has actually visited — logged when
/// they tap "Directions" on a pharmacy from the map. Only visited
/// pharmacies show up in the patient's pharmacy list (and can be reviewed).
class PharmacyVisitService {
  const PharmacyVisitService();

  CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance.collection('pharmacy_visits');

  Future<void> markVisited({
    required String patientId,
    required String pharmacyId,
  }) async {
    await _collection.doc('${patientId}_$pharmacyId').set({
      'patientId': patientId,
      'pharmacyId': pharmacyId,
      'visitedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Set<String>> fetchVisitedPharmacyIds(String patientId) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _collection
        .where('patientId', isEqualTo: patientId)
        .get();

    return {
      for (final doc in snapshot.docs) doc.data()['pharmacyId'] as String,
    };
  }
}
