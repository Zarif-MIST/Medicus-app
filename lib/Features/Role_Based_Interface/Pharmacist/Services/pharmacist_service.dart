import 'package:medicus/Features/Role_Based_Interface/Pharmacist/Models/pharmacy_prescription_queue_item.dart';

class PharmacistService {
  PharmacistService._();

  static final PharmacistService instance = PharmacistService._();

  static final List<_PharmacyPrescriptionRecord> _records = <_PharmacyPrescriptionRecord>[
    _PharmacyPrescriptionRecord(
      id: 'RX-1001',
      patientId: '4821',
      patientName: 'Tareq Hasan',
      doctorName: 'Dr. Farhana Rahman',
      status: 'Pending',
      medicines: <String>['Metformin 500mg', 'Vitamin B Complex'],
    ),
    _PharmacyPrescriptionRecord(
      id: 'RX-1002',
      patientId: '5634',
      patientName: 'Sadia Rahman',
      doctorName: 'Dr. Kamrul Islam',
      status: 'Pending',
      medicines: <String>['Amoxicillin 250mg'],
    ),
  ];

  Future<List<PharmacyPrescriptionQueueItem>> getPendingPrescriptions() async {
    // TODO(firebase): replace mock queue with Firestore prescriptions filtered by pending pharmacy fulfillment.
    return [
      for (final record in _records)
        if (record.status == 'Pending')
          record.toItem(),
    ];
  }

  Future<List<PharmacyPrescriptionQueueItem>> getDispensedPrescriptions() async {
    return [
      for (final record in _records)
        if (record.status == 'Dispensed')
          record.toItem(),
    ];
  }

  Future<int> getDispensedTodayCount() async {
    return _records.where((record) => record.status == 'Dispensed').length;
  }

  Future<List<MedicineInventoryItem>> getInventory() async {
    // TODO(firebase): replace mock inventory with Firestore or supplier-backed medicine inventory data.
    return const <MedicineInventoryItem>[
      MedicineInventoryItem(
        name: 'Metformin 500mg',
        stock: 120,
        supplier: 'Square Pharma',
      ),
      MedicineInventoryItem(
        name: 'Amoxicillin 250mg',
        stock: 64,
        supplier: 'Beximco Pharma',
      ),
      MedicineInventoryItem(
        name: 'Cetirizine 10mg',
        stock: 89,
        supplier: 'Incepta',
      ),
    ];
  }

  Future<void> markDispensed(String prescriptionId) async {
    // TODO(firebase): update prescription fulfillment status in Firestore.
    if (prescriptionId.trim().isEmpty) {
      throw ArgumentError('Prescription ID is required.');
    }

    for (final record in _records) {
      if (record.id == prescriptionId.trim()) {
        record.status = 'Dispensed';
        return;
      }
    }
  }
}

class _PharmacyPrescriptionRecord {
  _PharmacyPrescriptionRecord({
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
  String status;
  final List<String> medicines;

  PharmacyPrescriptionQueueItem toItem() {
    return PharmacyPrescriptionQueueItem(
      id: id,
      patientId: patientId,
      patientName: patientName,
      doctorName: doctorName,
      status: status,
      medicines: medicines,
    );
  }
}
