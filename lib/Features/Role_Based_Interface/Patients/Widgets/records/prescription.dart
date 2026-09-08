import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/home/prescription_timeline.dart';

class PrescriptionMedicine {
  const PrescriptionMedicine({
    required this.name,
    required this.dosage,
    required this.durationDays,
    this.quantity = 0,
    this.dispensedQuantity = 0,
  });

  final String name;
  final String dosage;
  final int durationDays;

  /// Total units for the full course, as written by the doctor.
  final int quantity;

  /// Units the pharmacy has actually handed over so far — can permanently
  /// sit below [quantity] if the patient only wanted part of their course.
  final int dispensedQuantity;

  int get remainingQuantity => (quantity - dispensedQuantity).clamp(0, quantity);

  bool get isFullyDispensed => quantity > 0 && dispensedQuantity >= quantity;

  bool get hasDispenseInfo => quantity > 0;
}

/// One prescription slip issued by a doctor — has its own id/date/doctor and
/// can bundle several medicines. Mirrors what a doctor-side "write
/// prescription" flow would eventually save (id + details, plus a PDF for
/// printing) — this side only reads/displays it.
class Prescription {
  const Prescription({
    required this.id,
    required this.doctorName,
    required this.date,
    required this.medicines,
  });

  final String id;
  final String doctorName;
  final DateTime date;
  final List<PrescriptionMedicine> medicines;

  int _dayCurrentFor(PrescriptionMedicine medicine) {
    final int daysSince = DateTime.now().difference(date).inDays;
    return daysSince.clamp(0, medicine.durationDays);
  }

  List<PrescriptionTimelineEntry> get timelineEntries {
    return [
      for (final medicine in medicines)
        PrescriptionTimelineEntry(
          medicineName: medicine.name,
          dosage: medicine.dosage,
          dayCurrent: _dayCurrentFor(medicine),
          dayTotal: medicine.durationDays,
          prescribedOn: date,
          doctorName: doctorName,
          prescriptionId: id,
        ),
    ];
  }

  bool get isCompleted => timelineEntries.every((entry) => entry.isCompleted);
}
