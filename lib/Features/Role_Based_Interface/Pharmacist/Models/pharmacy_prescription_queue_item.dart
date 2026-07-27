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
  final List<String> medicines;
}

class MedicineInventoryItem {
  const MedicineInventoryItem({
    required this.name,
    required this.stock,
    required this.supplier,
  });

  final String name;
  final int stock;
  final String supplier;
}
