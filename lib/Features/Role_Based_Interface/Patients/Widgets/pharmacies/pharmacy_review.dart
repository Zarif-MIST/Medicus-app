import 'package:cloud_firestore/cloud_firestore.dart';

/// A patient's 1-5 star rating and comment for a pharmacy they've visited.
class PharmacyReview {
  const PharmacyReview({
    required this.id,
    required this.pharmacyId,
    required this.patientId,
    required this.patientName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory PharmacyReview.fromFirestore(String id, Map<String, dynamic> data) {
    final Timestamp? timestamp = data['createdAt'] as Timestamp?;
    return PharmacyReview(
      id: id,
      pharmacyId: (data['pharmacyId'] as String?) ?? '',
      patientId: (data['patientId'] as String?) ?? '',
      patientName: (data['patientName'] as String?) ?? 'Patient',
      rating: (data['rating'] as num?)?.toInt() ?? 0,
      comment: (data['comment'] as String?) ?? '',
      createdAt: timestamp?.toDate() ?? DateTime.now(),
    );
  }

  final String id;
  final String pharmacyId;
  final String patientId;
  final String patientName;
  final int rating;
  final String comment;
  final DateTime createdAt;
}
