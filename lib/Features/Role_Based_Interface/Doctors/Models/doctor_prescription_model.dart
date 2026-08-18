class DoctorPrescriptionMedicine {
  const DoctorPrescriptionMedicine({
    required this.name,
    required this.dosage,
    required this.instructions,
    required this.durationDays,
  });

  final String name;
  final String dosage;
  final String instructions;
  final int durationDays;
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
