import 'package:cloud_firestore/cloud_firestore.dart';

/// The patient's recorded action on one [ScheduledDose] occurrence — taken
/// or snoozed. What's *scheduled* is always recomputed from the
/// prescriptions; this is the only part that's actually persisted, one
/// document per occurrence, keyed by `ScheduledDose.logId`.
class DoseLogEntry {
  const DoseLogEntry({
    required this.id,
    required this.patientId,
    required this.status,
    required this.scheduledAt,
    this.snoozeUntil,
  });

  static const String statusTaken = 'taken';
  static const String statusSnoozed = 'snoozed';

  final String id;
  final String patientId;
  final String status;
  final DateTime scheduledAt;
  final DateTime? snoozeUntil;

  bool get isTaken => status == statusTaken;

  bool get isActivelySnoozed => status == statusSnoozed && snoozeUntil != null && snoozeUntil!.isAfter(DateTime.now());

  factory DoseLogEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return DoseLogEntry(
      id: doc.id,
      patientId: data['patientId'] as String? ?? '',
      status: data['status'] as String? ?? '',
      scheduledAt: (data['scheduledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      snoozeUntil: (data['snoozeUntil'] as Timestamp?)?.toDate(),
    );
  }
}
