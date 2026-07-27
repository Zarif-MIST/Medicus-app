class DoctorPrescriptionMedicine {
  const DoctorPrescriptionMedicine({
    required this.name,
    required this.dosage,
    required this.instructions,
  });

  final String name;
  final String dosage;
  final String instructions;
}

class DoctorPrescriptionModel {
  const DoctorPrescriptionModel({
    required this.patientId,
    required this.doctorId,
    required this.specialty,
    required this.diagnosis,
    required this.medicines,
    required this.additionalNotes,
    required this.specialtyExtras,
  });

  final String patientId;
  final String doctorId;
  final String specialty;
  final String diagnosis;
  final List<DoctorPrescriptionMedicine> medicines;
  final String additionalNotes;
  final Map<String, String> specialtyExtras;
}
