import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicus/Features/Role_Based_Interface/Pharmacist/Models/inventory_transaction.dart';
import 'package:medicus/Features/Role_Based_Interface/Pharmacist/Models/medicine_shortfall.dart';
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
        for (final rawMedicine in rawMedicines) _medicineFromFirestore(rawMedicine as Map<String, dynamic>),
      ],
    );
  }

  PrescribedMedicine _medicineFromFirestore(Map<String, dynamic> data) {
    final String frequency = (data['frequency'] ?? '').toString().trim();
    final int? durationDays = (data['durationDays'] as num?)?.toInt();
    final String instructions = (data['instructions'] ?? '').toString().trim();

    return PrescribedMedicine(
      name: (data['name'] ?? '').toString(),
      dosage: (data['dosage'] ?? '').toString(),
      frequency: frequency.isEmpty ? 'As directed' : frequency,
      duration: durationDays == null ? 'Not specified' : '$durationDays days',
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
      instructions: instructions.isEmpty ? null : instructions,
    );
  }

  static final List<MedicineInventoryItem> _inventory = <MedicineInventoryItem>[
    const MedicineInventoryItem(
      name: 'Metformin 500mg',
      stock: 120,
      supplier: 'Square Pharma',
      lowStockThreshold: 30,
    ),
    const MedicineInventoryItem(
      name: 'Amoxicillin 250mg',
      stock: 60,
      supplier: 'Beximco Pharma',
      lowStockThreshold: 25,
    ),
    const MedicineInventoryItem(
      name: 'Cetirizine 10mg',
      stock: 80,
      supplier: 'Incepta',
      lowStockThreshold: 20,
    ),
  ];

  Future<List<MedicineInventoryItem>> getInventory() async {
    // TODO(firebase): replace mock inventory with Firestore or supplier-backed medicine inventory data.
    return List<MedicineInventoryItem>.unmodifiable(_inventory);
  }

  Future<List<MedicineInventoryItem>> getLowStockItems() async {
    return _inventory.where((MedicineInventoryItem item) => item.isLowStock).toList();
  }

  static final List<InventoryTransaction> _transactions = <InventoryTransaction>[];

  void _logTransaction({
    required String medicineName,
    required InventoryTransactionType type,
    required int delta,
    required int resultingStock,
    required String reason,
  }) {
    _transactions.insert(
      0,
      InventoryTransaction(
        medicineName: medicineName,
        type: type,
        delta: delta,
        resultingStock: resultingStock,
        reason: reason,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<List<InventoryTransaction>> getInventoryLog() async {
    // TODO(firebase): replace mock log with a Firestore-backed inventory ledger.
    return List<InventoryTransaction>.unmodifiable(_transactions);
  }

  Future<void> addInventoryItem(MedicineInventoryItem item) async {
    _inventory.add(item);
    _logTransaction(
      medicineName: item.name,
      type: InventoryTransactionType.added,
      delta: item.stock,
      resultingStock: item.stock,
      reason: 'Added to inventory',
    );
  }

  Future<void> removeInventoryItem(String name) async {
    final int index = _inventory.indexWhere((MedicineInventoryItem item) => item.name == name);
    if (index == -1) {
      return;
    }

    final MedicineInventoryItem removed = _inventory.removeAt(index);
    _logTransaction(
      medicineName: removed.name,
      type: InventoryTransactionType.removed,
      delta: -removed.stock,
      resultingStock: 0,
      reason: 'Removed from inventory',
    );
  }

  Future<void> changeInventoryStock(
    String name,
    int delta, {
    InventoryTransactionType type = InventoryTransactionType.adjustment,
    String? reason,
  }) async {
    final int index = _inventory.indexWhere((MedicineInventoryItem item) => item.name == name);
    if (index == -1) {
      return;
    }

    final MedicineInventoryItem current = _inventory[index];
    final int updatedStock = current.stock + delta;
    if (updatedStock < 0) {
      return;
    }

    _inventory[index] = MedicineInventoryItem(
      name: current.name,
      stock: updatedStock,
      supplier: current.supplier,
      lowStockThreshold: current.lowStockThreshold,
    );

    _logTransaction(
      medicineName: current.name,
      type: type,
      delta: delta,
      resultingStock: updatedStock,
      reason: reason ?? (delta >= 0 ? 'Stock added' : 'Stock removed'),
    );
  }

  int _availableStockOf(String medicineName) {
    final int index = _inventory.indexWhere((MedicineInventoryItem item) => item.name == medicineName);
    return index == -1 ? 0 : _inventory[index].stock;
  }

  /// Returns the medicines that don't have enough stock to fulfil [medicines],
  /// empty if everything required is available.
  List<MedicineShortfall> checkStockAvailability(List<PrescribedMedicine> medicines) {
    return [
      for (final PrescribedMedicine medicine in medicines)
        if (_availableStockOf(medicine.name) < medicine.quantity)
          MedicineShortfall(
            medicineName: medicine.name,
            requiredQuantity: medicine.quantity,
            availableStock: _availableStockOf(medicine.name),
          ),
    ];
  }

  Future<void> markDispensed(String prescriptionId) async {
    final String id = prescriptionId.trim();
    if (id.isEmpty) {
      throw ArgumentError('Prescription ID is required.');
    }

    final DocumentSnapshot<Map<String, dynamic>> doc =
        await _firestore.collection('prescriptions').doc(id).get();
    final Map<String, dynamic>? data = doc.data();
    if (!doc.exists || data == null) {
      throw ArgumentError('Prescription $id was not found.');
    }

    final PharmacyPrescriptionQueueItem item = _fromFirestore(doc.id, data, status: 'Pending');

    final List<MedicineShortfall> shortfalls = checkStockAvailability(item.medicines);
    if (shortfalls.isNotEmpty) {
      throw InsufficientStockException(shortfalls);
    }

    for (final PrescribedMedicine medicine in item.medicines) {
      await changeInventoryStock(
        medicine.name,
        -medicine.quantity,
        type: InventoryTransactionType.dispensed,
        reason: 'Dispensed for prescription $id',
      );
    }

    await _firestore.collection('prescriptions').doc(id).update(<String, dynamic>{
      'status': 'dispensed',
    });
  }
}
