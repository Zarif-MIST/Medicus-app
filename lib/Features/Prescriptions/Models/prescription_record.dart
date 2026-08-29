import 'package:cloud_firestore/cloud_firestore.dart';

/// One medicine line on a prescription, as written by the doctor.
class PrescriptionRecordMedicine {
  const PrescriptionRecordMedicine({
    required this.name,
    required this.dosage,
    required this.instructions,
    required this.durationDays,
    this.doseTimes = const [],
  });

  final String name;
  final String dosage;
  final String instructions;
  final int durationDays;

  /// Clock times this medicine is due each day it's active, as "HH:mm"
  /// 24-hour strings (e.g. "08:00", "20:00") — set by the doctor when
  /// writing the prescription. Powers the patient's dose schedule/adherence
  /// tracking; empty means this medicine was written before that existed
  /// (or the doctor skipped it) and won't appear in the dose schedule.
  final List<String> doseTimes;

  Map<String, dynamic> toJson() => {
        'name': name,
        'dosage': dosage,
        'instructions': instructions,
        'durationDays': durationDays,
        'doseTimes': doseTimes,
      };

  factory PrescriptionRecordMedicine.fromJson(Map<String, dynamic> json) {
    return PrescriptionRecordMedicine(
      name: json['name'] as String? ?? '',
      dosage: json['dosage'] as String? ?? '',
      instructions: json['instructions'] as String? ?? '',
      durationDays: (json['durationDays'] as num?)?.toInt() ?? 0,
      doseTimes: [
        for (final t in (json['doseTimes'] as List<dynamic>? ?? const [])) t as String,
      ],
    );
  }
}

/// The canonical, Firestore-backed prescription — written once by a doctor,
/// then read by the patient (home, records, PDF/QR) and the pharmacist
/// (fulfillment queue), with a single `status` both sides agree on.
///
/// This is the one real record behind three role-specific view models:
/// `Patients/Widgets/records/prescription.dart` (`Prescription`),
/// `Pharmacist/Models/pharmacy_prescription_queue_item.dart`
/// (`PharmacyPrescriptionQueueItem`), and the doctor's own write-form draft
/// (`Doctors/Models/doctor_prescription_model.dart`). Each role keeps mapping
/// into its existing type rather than the whole app switching to this one,
/// so screens built against those types don't need to change.
class PrescriptionRecord {
  const PrescriptionRecord({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.specialty,
    required this.diagnosis,
    required this.additionalNotes,
    required this.medicines,
    required this.status,
    required this.createdAt,
    this.dispensedAt,
  });

  static const String statusPending = 'Pending';
  static const String statusDispensed = 'Dispensed';

  final String id;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String specialty;
  final String diagnosis;
  final String additionalNotes;
  final List<PrescriptionRecordMedicine> medicines;
  final String status;
  final DateTime createdAt;
  final DateTime? dispensedAt;

  /// Whether every medicine's course has run its full length — the same
  /// day-elapsed-vs-duration check the patient's dose/timeline views use
  /// (`Prescription.isCompleted`), so a prescription never shows as
  /// "ongoing" to the patient and "previous" to the doctor or vice versa.
  bool get isCompleted {
    if (medicines.isEmpty) return false;
    final int daysSince = DateTime.now().difference(createdAt).inDays;
    return medicines.every((medicine) => daysSince >= medicine.durationDays);
  }

  Map<String, dynamic> toCreateJson() => {
        'patientId': patientId,
        'patientName': patientName,
        'doctorId': doctorId,
        'doctorName': doctorName,
        'specialty': specialty,
        'diagnosis': diagnosis,
        'additionalNotes': additionalNotes,
        'medicines': [for (final m in medicines) m.toJson()],
        'status': statusPending,
        'createdAt': FieldValue.serverTimestamp(),
        'dispensedAt': null,
      };

  factory PrescriptionRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return PrescriptionRecord(
      id: doc.id,
      patientId: data['patientId'] as String? ?? '',
      patientName: data['patientName'] as String? ?? '',
      doctorId: data['doctorId'] as String? ?? '',
      doctorName: data['doctorName'] as String? ?? '',
      specialty: data['specialty'] as String? ?? '',
      diagnosis: data['diagnosis'] as String? ?? '',
      additionalNotes: data['additionalNotes'] as String? ?? '',
      medicines: [
        for (final item in (data['medicines'] as List<dynamic>? ?? const []))
          PrescriptionRecordMedicine.fromJson(item as Map<String, dynamic>),
      ],
      status: data['status'] as String? ?? PrescriptionRecord.statusPending,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dispensedAt: (data['dispensedAt'] as Timestamp?)?.toDate(),
    );
  }
}
