class DoctorPrescriptionMedicine {
  const DoctorPrescriptionMedicine({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.instructions,
    required this.durationDays,
    required this.quantity,
  });

  final String name;
  final String dosage;
  final String frequency;
  final String instructions;
  final int durationDays;

  /// Total units the pharmacist should dispense for this course.
  final int quantity;
}

class DoctorPrescriptionModel {
  const DoctorPrescriptionModel({
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.specialty,
    required this.diagnosis,
    required this.medicines,
    required this.additionalNotes,
    required this.specialtyExtras,
  });

  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String specialty;
  final String diagnosis;
  final List<DoctorPrescriptionMedicine> medicines;
  final String additionalNotes;
  final Map<String, String> specialtyExtras;
}
