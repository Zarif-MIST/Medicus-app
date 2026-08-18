import 'package:medicus/Features/Role_Based_Interface/Pharmacist/Models/inventory_transaction.dart';
import 'package:medicus/Features/Role_Based_Interface/Pharmacist/Models/medicine_shortfall.dart';
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
      medicines: <PrescribedMedicine>[
        const PrescribedMedicine(
          name: 'Metformin 500mg',
          dosage: '1 tablet',
          frequency: 'Twice daily',
          duration: '30 days',
          quantity: 60,
          instructions: 'Take after meals',
        ),
        const PrescribedMedicine(
          name: 'Vitamin B Complex',
          dosage: '1 capsule',
          frequency: 'Once daily',
          duration: '30 days',
          quantity: 30,
        ),
      ],
    ),
    _PharmacyPrescriptionRecord(
      id: 'RX-1002',
      patientId: '5634',
      patientName: 'Sadia Rahman',
      doctorName: 'Dr. Kamrul Islam',
      status: 'Pending',
      medicines: <PrescribedMedicine>[
        const PrescribedMedicine(
          name: 'Amoxicillin 250mg',
          dosage: '1 capsule',
          frequency: 'Three times daily',
          duration: '7 days',
          quantity: 21,
          instructions: 'Complete the full course even if symptoms improve',
        ),
      ],
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
    // TODO(firebase): update prescription fulfillment status in Firestore.
    if (prescriptionId.trim().isEmpty) {
      throw ArgumentError('Prescription ID is required.');
    }

    for (final record in _records) {
      if (record.id == prescriptionId.trim()) {
        final List<MedicineShortfall> shortfalls = checkStockAvailability(record.medicines);
        if (shortfalls.isNotEmpty) {
          throw InsufficientStockException(shortfalls);
        }

        record.status = 'Dispensed';
        for (final PrescribedMedicine medicine in record.medicines) {
          await changeInventoryStock(
            medicine.name,
            -medicine.quantity,
            type: InventoryTransactionType.dispensed,
            reason: 'Dispensed for prescription ${record.id}',
          );
        }
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
  final List<PrescribedMedicine> medicines;

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
