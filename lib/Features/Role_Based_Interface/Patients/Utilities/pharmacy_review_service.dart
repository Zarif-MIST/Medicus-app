import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/pharmacies/pharmacy_review.dart';

/// Reads and writes patient reviews for registered pharmacies. One review
/// per patient per pharmacy — submitting again overwrites their previous one.
class PharmacyReviewService {
  const PharmacyReviewService();

  CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance.collection('pharmacy_reviews');

  Future<List<PharmacyReview>> fetchReviews(String pharmacyId) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _collection.where('pharmacyId', isEqualTo: pharmacyId).get();

    final List<PharmacyReview> reviews =
        [for (final doc in snapshot.docs) PharmacyReview.fromFirestore(doc.id, doc.data())]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return reviews;
  }

  Future<void> submitReview({
    required String pharmacyId,
    required String patientId,
    required String patientName,
    required int rating,
    required String comment,
  }) async {
    await _collection.doc('${pharmacyId}_$patientId').set({
      'pharmacyId': pharmacyId,
      'patientId': patientId,
      'patientName': patientName,
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static double averageRating(List<PharmacyReview> reviews) {
    if (reviews.isEmpty) return 0;
    final double total = reviews.fold(0, (acc, review) => acc + review.rating);
    return total / reviews.length;
  }
}
