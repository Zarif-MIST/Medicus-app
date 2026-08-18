class PrescribedMedicine {
  const PrescribedMedicine({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.duration,
    required this.quantity,
    this.instructions,
  });

  /// Medicine name including strength, e.g. "Metformin 500mg" — also the key
  /// used to match against inventory stock.
  final String name;

  /// Amount per dose, e.g. "1 tablet".
  final String dosage;

  /// How often to take it, e.g. "Twice daily".
  final String frequency;

  /// How long the course runs, e.g. "10 days".
  final String duration;

  /// Total units to dispense from inventory for this course.
  final int quantity;

  /// Optional extra guidance, e.g. "Take after meals".
  final String? instructions;
}

class PharmacyPrescriptionQueueItem {
  const PharmacyPrescriptionQueueItem({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorName,
    required this.status,
    required this.medicines,
  });

  final String id;
  final String patientId;
  final String patientName;
  final String doctorName;
  final String status;
  final List<PrescribedMedicine> medicines;
}

class MedicineInventoryItem {
  const MedicineInventoryItem({
    required this.name,
    required this.stock,
    required this.supplier,
    this.lowStockThreshold = 20,
  });

  final String name;
  final int stock;
  final String supplier;

  /// Stock level at or below which this medicine is flagged as needing restock.
  final int lowStockThreshold;

  bool get isLowStock => stock <= lowStockThreshold;
}
