import 'package:medicus/Features/Prescriptions/Models/prescription_record.dart';

/// One occurrence of a medicine being due — computed on the fly from a
/// patient's active prescriptions, never stored. Firestore only remembers
/// what the patient *did* about it (see `DoseLogEntry`); what's *scheduled*
/// is always re-derived from the prescription + its duration, so a dose
/// schedule never drifts out of sync with the prescriptions behind it.
class ScheduledDose {
  const ScheduledDose({
    required this.prescriptionId,
    required this.medicineIndex,
    required this.medicineName,
    required this.dosage,
    required this.instructions,
    required this.doctorName,
    required this.scheduledAt,
  });

  final String prescriptionId;
  final int medicineIndex;
  final String medicineName;
  final String dosage;
  final String instructions;
  final String doctorName;
  final DateTime scheduledAt;

  /// Deterministic Firestore document id for this exact occurrence, so
  /// "mark as taken" is an idempotent set/update rather than an append.
  String get logId {
    final String dateKey =
        '${scheduledAt.year.toString().padLeft(4, '0')}${scheduledAt.month.toString().padLeft(2, '0')}${scheduledAt.day.toString().padLeft(2, '0')}';
    final String timeKey =
        '${scheduledAt.hour.toString().padLeft(2, '0')}${scheduledAt.minute.toString().padLeft(2, '0')}';
    return '${prescriptionId}_${medicineIndex}_${dateKey}_$timeKey';
  }

  bool isSameDayAs(DateTime other) =>
      scheduledAt.year == other.year &&
      scheduledAt.month == other.month &&
      scheduledAt.day == other.day;

  /// Groups this dose with others that schedule the same medicine at the
  /// same clock time — used to detect two different prescriptions
  /// accidentally (or deliberately) overlapping. Not unique across days, by
  /// design: [overlappingDoseKeys] is always computed over doses already
  /// scoped to a single day.
  String get overlapKey =>
      '${medicineName.trim().toLowerCase()}_${scheduledAt.hour}:${scheduledAt.minute}';
}

/// Medicine+time combinations in [doses] that come from more than one
/// distinct prescription — a likely sign of overlapping/duplicate courses
/// (e.g. a follow-up visit re-prescribing the same medicine while the prior
/// course is still active, or two different doctors independently
/// prescribing it) that the patient should confirm with their doctor or
/// pharmacist rather than the app silently merging or hiding either one.
Set<String> overlappingDoseKeys(List<ScheduledDose> doses) {
  final Map<String, Set<String>> prescriptionIdsByKey = {};
  for (final ScheduledDose dose in doses) {
    (prescriptionIdsByKey[dose.overlapKey] ??= <String>{}).add(
      dose.prescriptionId,
    );
  }
  return {
    for (final MapEntry<String, Set<String>> entry
        in prescriptionIdsByKey.entries)
      if (entry.value.length > 1) entry.key,
  };
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Parses a doctor-entered "HH:mm" string into an hour/minute pair. Falls
/// back to midnight for anything malformed rather than throwing — a bad
/// value shouldn't take down the whole schedule computation.
(int, int) _parseTime(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length != 2) return (0, 0);
  final int? h = int.tryParse(parts[0]);
  final int? m = int.tryParse(parts[1]);
  return (h ?? 0, m ?? 0);
}

/// Expands every medicine with dose times across [prescriptions] into the
/// individual [ScheduledDose] occurrences falling within
/// [rangeStart]..[rangeEnd] inclusive (both date-only, any dispensed/
/// undispensed status — a prescription stays on the schedule regardless of
/// pharmacy pickup, since the patient is still meant to take the medicine).
List<ScheduledDose> expandDoseSchedule({
  required List<PrescriptionRecord> prescriptions,
  required DateTime rangeStart,
  required DateTime rangeEnd,
}) {
  final DateTime start = _dateOnly(rangeStart);
  final DateTime end = _dateOnly(rangeEnd);
  final List<ScheduledDose> doses = [];

  for (final record in prescriptions) {
    final DateTime prescribedOn = _dateOnly(record.createdAt);

    for (
      int medicineIndex = 0;
      medicineIndex < record.medicines.length;
      medicineIndex++
    ) {
      final PrescriptionRecordMedicine medicine =
          record.medicines[medicineIndex];
      if (medicine.doseTimes.isEmpty || medicine.durationDays <= 0) continue;

      final DateTime courseEnd = prescribedOn.add(
        Duration(days: medicine.durationDays - 1),
      );
      DateTime day = prescribedOn.isAfter(start) ? prescribedOn : start;
      final DateTime lastDay = courseEnd.isBefore(end) ? courseEnd : end;

      while (!day.isAfter(lastDay)) {
        for (final String hhmm in medicine.doseTimes) {
          final (hour, minute) = _parseTime(hhmm);
          doses.add(
            ScheduledDose(
              prescriptionId: record.id,
              medicineIndex: medicineIndex,
              medicineName: medicine.name,
              dosage: medicine.dosage,
              instructions: medicine.instructions,
              doctorName: record.doctorName,
              scheduledAt: DateTime(day.year, day.month, day.day, hour, minute),
            ),
          );
        }
        day = day.add(const Duration(days: 1));
      }
    }
  }

  doses.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  return doses;
}
