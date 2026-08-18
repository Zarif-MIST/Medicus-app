import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicus/Features/Role_Based_Interface/Pharmacist/Models/pharmacy_prescription_queue_item.dart';

class PharmacistService {
  PharmacistService._();

  static final PharmacistService instance = PharmacistService._();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<PharmacyPrescriptionQueueItem>> getPendingPrescriptions() async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('prescriptions')
        .where('status', isEqualTo: 'pendingPharmacy')
        .get();

    return [
      for (final doc in snapshot.docs)
        _fromFirestore(doc.id, doc.data(), status: 'Pending'),
    ];
  }

  Future<List<PharmacyPrescriptionQueueItem>> getDispensedPrescriptions() async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('prescriptions')
        .where('status', isEqualTo: 'dispensed')
        .get();

    return [
      for (final doc in snapshot.docs)
        _fromFirestore(doc.id, doc.data(), status: 'Dispensed'),
    ];
  }

  Future<int> getDispensedTodayCount() async {
    final List<PharmacyPrescriptionQueueItem> dispensed =
        await getDispensedPrescriptions();
    return dispensed.length;
  }

  PharmacyPrescriptionQueueItem _fromFirestore(
    String id,
    Map<String, dynamic> data, {
    required String status,
  }) {
    final List<dynamic> rawMedicines =
        (data['medicines'] as List<dynamic>?) ?? const <dynamic>[];

    return PharmacyPrescriptionQueueItem(
      id: id,
      patientId: (data['patientId'] ?? '') as String,
      patientName: (data['patientName'] ?? '') as String,
      doctorName: (data['doctorName'] ?? '') as String,
      status: status,
      medicines: [
        for (final rawMedicine in rawMedicines) (rawMedicine['name'] ?? '') as String,
      ],
    );
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
    final String id = prescriptionId.trim();
    if (id.isEmpty) {
      throw ArgumentError('Prescription ID is required.');
    }

    await _firestore.collection('prescriptions').doc(id).update(<String, dynamic>{
      'status': 'dispensed',
    });
  }
}
