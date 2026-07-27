import 'package:medicus/Features/Role_Based_Interface/Pharmacist/Models/pharmacy_prescription_queue_item.dart';

class PharmacistService {
  PharmacistService._();

  static final PharmacistService instance = PharmacistService._();

  Future<List<PharmacyPrescriptionQueueItem>> getPendingPrescriptions() async {
    // TODO(firebase): replace mock queue with Firestore prescriptions filtered by pending pharmacy fulfillment.
    return const <PharmacyPrescriptionQueueItem>[
      PharmacyPrescriptionQueueItem(
        id: 'RX-1001',
        patientId: '4821',
        patientName: 'Tareq Hasan',
        doctorName: 'Dr. Farhana Rahman',
        status: 'Pending',
        medicines: <String>['Metformin 500mg', 'Vitamin B Complex'],
      ),
      PharmacyPrescriptionQueueItem(
        id: 'RX-1002',
        patientId: '5634',
        patientName: 'Sadia Rahman',
        doctorName: 'Dr. Kamrul Islam',
        status: 'Ready',
        medicines: <String>['Amoxicillin 250mg'],
      ),
    ];
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
  }
}
