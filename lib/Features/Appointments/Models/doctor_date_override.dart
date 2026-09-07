import 'package:cloud_firestore/cloud_firestore.dart';

/// A doctor's per-date exception on top of their normal recurring weekly
/// availability — set from the Service Planner calendar. Most dates have no
/// override at all and just fall back to the existing weekday-based
/// schedule; this only covers the dates a doctor has explicitly touched.
enum DoctorDateStatus {
  /// Explicitly confirmed as open — shown to patients as confirmed
  /// availability. Booking already falls back to the doctor's normal
  /// schedule for unmarked dates, so this is mainly a clear, visible
  /// confirmation for both doctor and patient.
  available,

  /// A day off — leave, holiday, etc. Hides the date from patient booking
  /// even if it would otherwise be available under the doctor's normal
  /// weekday schedule.
  blocked;

  String get storageValue => name;

  static DoctorDateStatus fromStorage(String? value) {
    return DoctorDateStatus.values.firstWhere(
      (status) => status.storageValue == value,
      orElse: () => DoctorDateStatus.available,
    );
  }
}

class DoctorDateOverride {
  const DoctorDateOverride({
    required this.doctorId,
    required this.date,
    required this.status,
  });

  final String doctorId;

  /// Midnight of the overridden calendar day.
  final DateTime date;
  final DoctorDateStatus status;

  static String docIdFor(String doctorId, DateTime date) {
    final String stamp =
        '${date.year.toString().padLeft(4, '0')}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    return '${doctorId}_$stamp';
  }

  Map<String, dynamic> toJson() => {
    'doctorId': doctorId,
    'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
    'status': status.storageValue,
  };

  factory DoctorDateOverride.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return DoctorDateOverride(
      doctorId: data['doctorId'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: DoctorDateStatus.fromStorage(data['status'] as String?),
    );
  }
}
