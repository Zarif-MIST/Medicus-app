import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicus/Features/Prescriptions/Models/dose_log_entry.dart';
import 'package:medicus/Features/Prescriptions/Models/scheduled_dose.dart';

/// Firestore-backed log of what a patient actually did about each scheduled
/// dose. A single equality filter on `patientId` only (no compound query),
/// same convention as the rest of this app's Firestore reads — date-range
/// filtering (today / this week) happens client-side on the small result set.
class DoseLogRepository {
  const DoseLogRepository();

  CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance.collection('dose_logs');

  Future<List<DoseLogEntry>> fetchForPatient(String patientId) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _collection.where('patientId', isEqualTo: patientId).get();
    return snapshot.docs.map(DoseLogEntry.fromDoc).toList();
  }

  Future<void> markTaken({required String patientId, required ScheduledDose dose}) async {
    await _collection.doc(dose.logId).set({
      'patientId': patientId,
      'prescriptionId': dose.prescriptionId,
      'medicineIndex': dose.medicineIndex,
      'medicineName': dose.medicineName,
      'scheduledAt': Timestamp.fromDate(dose.scheduledAt),
      'status': DoseLogEntry.statusTaken,
      'actedAt': FieldValue.serverTimestamp(),
      'snoozeUntil': null,
    });
  }

  Future<void> markSnoozed({
    required String patientId,
    required ScheduledDose dose,
    Duration snoozeFor = const Duration(minutes: 30),
  }) async {
    await _collection.doc(dose.logId).set({
      'patientId': patientId,
      'prescriptionId': dose.prescriptionId,
      'medicineIndex': dose.medicineIndex,
      'medicineName': dose.medicineName,
      'scheduledAt': Timestamp.fromDate(dose.scheduledAt),
      'status': DoseLogEntry.statusSnoozed,
      'actedAt': FieldValue.serverTimestamp(),
      'snoozeUntil': Timestamp.fromDate(DateTime.now().add(snoozeFor)),
    });
  }

  /// Reverts a dose back to "not yet acted on" — used when a patient taps an
  /// already-taken dose in the schedule to undo a mistaken mark.
  Future<void> clearLog(String logId) => _collection.doc(logId).delete();
}
