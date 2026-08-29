import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicus/Features/Prescriptions/Models/prescription_record.dart';
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
        .where('status', isEqualTo: PrescriptionRecord.statusPending)
        .get();

    return [
      for (final doc in snapshot.docs)
        _fromFirestore(doc.id, doc.data(), status: PrescriptionRecord.statusPending),
    ];
  }

  /// Used for the pharmacist's QR scan flow: only the scanned patient's own
  /// pending prescription(s) are returned — nothing else about the patient
  /// or any other patient's data is exposed. Fetches by `patientId` alone and
  /// filters `status` client-side, since this project avoids combined-filter
  /// Firestore queries that need a composite index.
  Future<List<PharmacyPrescriptionQueueItem>> getPendingPrescriptionsForPatient(
    String patientId,
  ) async {
    final String id = patientId.trim();
    if (id.isEmpty) {
      return const [];
    }

    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('prescriptions')
        .where('patientId', isEqualTo: id)
        .get();

    return [
      for (final doc in snapshot.docs)
        if ((doc.data()['status'] ?? '') == PrescriptionRecord.statusPending)
          _fromFirestore(doc.id, doc.data(), status: PrescriptionRecord.statusPending),
    ];
  }

  Future<List<PharmacyPrescriptionQueueItem>>
  getDispensedPrescriptions() async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('prescriptions')
        .where('status', isEqualTo: PrescriptionRecord.statusDispensed)
        .get();

    return [
      for (final doc in snapshot.docs)
        _fromFirestore(doc.id, doc.data(), status: PrescriptionRecord.statusDispensed),
    ];
  }

  /// Prescriptions dispensed today, newest first — filtered client-side
  /// against [dispensedAt] to avoid a composite Firestore index.
  Future<List<PharmacyPrescriptionQueueItem>> getDispensedToday() async {
    final List<PharmacyPrescriptionQueueItem> dispensed =
        await getDispensedPrescriptions();
    final DateTime now = DateTime.now();

    final List<PharmacyPrescriptionQueueItem> today = dispensed.where((
      PharmacyPrescriptionQueueItem item,
    ) {
      final DateTime? dispensedAt = item.dispensedAt;
      return dispensedAt != null &&
          dispensedAt.year == now.year &&
          dispensedAt.month == now.month &&
          dispensedAt.day == now.day;
    }).toList();

    today.sort((a, b) => b.dispensedAt!.compareTo(a.dispensedAt!));
    return today;
  }

  PharmacyPrescriptionQueueItem _fromFirestore(
    String id,
    Map<String, dynamic> data, {
    required String status,
  }) {
    final List<dynamic> rawMedicines =
        (data['medicines'] as List<dynamic>?) ?? const <dynamic>[];
    final Object? rawDispensedAt = data['dispensedAt'];

    return PharmacyPrescriptionQueueItem(
      id: id,
      patientId: (data['patientId'] ?? '') as String,
      patientName: (data['patientName'] ?? '') as String,
      doctorName: (data['doctorName'] ?? '') as String,
      status: status,
      medicines: [
        for (final rawMedicine in rawMedicines)
          _medicineFromFirestore(rawMedicine as Map<String, dynamic>),
      ],
      dispensedAt: rawDispensedAt is Timestamp ? rawDispensedAt.toDate() : null,
    );
  }

  PrescribedMedicine _medicineFromFirestore(Map<String, dynamic> data) {
    final String frequency = (data['frequency'] ?? '').toString().trim();
    final int? durationDays = (data['durationDays'] as num?)?.toInt();
    final String instructions = (data['instructions'] ?? '').toString().trim();
    final int dosesPerDay = (data['doseTimes'] as List<dynamic>?)?.length ?? 0;

    // Older prescriptions stored an explicit `quantity`; the current
    // doctor-side form only records `durationDays` and `doseTimes`, so
    // derive a reasonable total (one unit per scheduled dose) instead of
    // silently assuming 1 and under-deducting inventory.
    final int? explicitQuantity = (data['quantity'] as num?)?.toInt();
    final int derivedQuantity = durationDays != null && dosesPerDay > 0
        ? durationDays * dosesPerDay
        : (durationDays ?? 1);

    return PrescribedMedicine(
      name: (data['name'] ?? '').toString(),
      dosage: (data['dosage'] ?? '').toString(),
      frequency: frequency.isEmpty ? 'As directed' : frequency,
      duration: durationDays == null ? 'Not specified' : '$durationDays days',
      quantity: explicitQuantity ?? derivedQuantity,
      instructions: instructions.isEmpty ? null : instructions,
    );
  }

  /// Inventory is scoped per pharmacist: each pharmacist manages their own
  /// stock, so every inventory/log operation requires their [pharmacistId]
  /// (their Firebase Auth UID).
  Future<List<MedicineInventoryItem>> getInventory(String pharmacistId) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('inventory')
        .where('pharmacistId', isEqualTo: pharmacistId)
        .get();

    return [
      for (final doc in snapshot.docs) _inventoryItemFromFirestore(doc.data()),
    ];
  }

  MedicineInventoryItem _inventoryItemFromFirestore(Map<String, dynamic> data) {
    return MedicineInventoryItem(
      name: (data['name'] ?? '').toString(),
      stock: (data['stock'] as num?)?.toInt() ?? 0,
      supplier: (data['supplier'] ?? '').toString(),
      lowStockThreshold: (data['lowStockThreshold'] as num?)?.toInt() ?? 20,
    );
  }

  Future<List<MedicineInventoryItem>> getLowStockItems(
    String pharmacistId,
  ) async {
    final List<MedicineInventoryItem> inventory = await getInventory(
      pharmacistId,
    );
    return inventory
        .where((MedicineInventoryItem item) => item.isLowStock)
        .toList();
  }

  Future<void> _logTransaction({
    required String pharmacistId,
    required String medicineName,
    required InventoryTransactionType type,
    required int delta,
    required int resultingStock,
    required String reason,
  }) async {
    await _firestore.collection('inventory_transactions').add(<String, dynamic>{
      'pharmacistId': pharmacistId,
      'medicineName': medicineName,
      'type': type.name,
      'delta': delta,
      'resultingStock': resultingStock,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<List<InventoryTransaction>> getInventoryLog(
    String pharmacistId,
  ) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('inventory_transactions')
        .where('pharmacistId', isEqualTo: pharmacistId)
        .get();

    final List<InventoryTransaction> transactions = [
      for (final doc in snapshot.docs) _transactionFromFirestore(doc.data()),
    ];
    transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return transactions;
  }

  InventoryTransaction _transactionFromFirestore(Map<String, dynamic> data) {
    final Object? rawTimestamp = data['timestamp'];
    return InventoryTransaction(
      medicineName: (data['medicineName'] ?? '').toString(),
      type: InventoryTransactionType.values.firstWhere(
        (InventoryTransactionType t) => t.name == data['type'],
        orElse: () => InventoryTransactionType.adjustment,
      ),
      delta: (data['delta'] as num?)?.toInt() ?? 0,
      resultingStock: (data['resultingStock'] as num?)?.toInt() ?? 0,
      reason: (data['reason'] ?? '').toString(),
      timestamp: rawTimestamp is Timestamp
          ? rawTimestamp.toDate()
          : DateTime.now(),
    );
  }

  Future<void> addInventoryItem(
    String pharmacistId,
    MedicineInventoryItem item,
  ) async {
    await _firestore.collection('inventory').add(<String, dynamic>{
      'pharmacistId': pharmacistId,
      'name': item.name,
      'stock': item.stock,
      'supplier': item.supplier,
      'lowStockThreshold': item.lowStockThreshold,
    });

    await _logTransaction(
      pharmacistId: pharmacistId,
      medicineName: item.name,
      type: InventoryTransactionType.added,
      delta: item.stock,
      resultingStock: item.stock,
      reason: 'Added to inventory',
    );
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _findInventoryDoc(
    String pharmacistId,
    String name,
  ) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('inventory')
        .where('pharmacistId', isEqualTo: pharmacistId)
        .where('name', isEqualTo: name)
        .limit(1)
        .get();
    return snapshot.docs.isEmpty ? null : snapshot.docs.first;
  }

  Future<void> removeInventoryItem(String pharmacistId, String name) async {
    final QueryDocumentSnapshot<Map<String, dynamic>>? doc =
        await _findInventoryDoc(pharmacistId, name);
    if (doc == null) {
      return;
    }

    final int stock = (doc.data()['stock'] as num?)?.toInt() ?? 0;
    await doc.reference.delete();

    await _logTransaction(
      pharmacistId: pharmacistId,
      medicineName: name,
      type: InventoryTransactionType.removed,
      delta: -stock,
      resultingStock: 0,
      reason: 'Removed from inventory',
    );
  }

  Future<void> changeInventoryStock(
    String pharmacistId,
    String name,
    int delta, {
    InventoryTransactionType type = InventoryTransactionType.adjustment,
    String? reason,
  }) async {
    final QueryDocumentSnapshot<Map<String, dynamic>>? doc =
        await _findInventoryDoc(pharmacistId, name);
    if (doc == null) {
      return;
    }

    final int currentStock = (doc.data()['stock'] as num?)?.toInt() ?? 0;
    final int updatedStock = currentStock + delta;
    if (updatedStock < 0) {
      return;
    }

    await doc.reference.update(<String, dynamic>{'stock': updatedStock});

    await _logTransaction(
      pharmacistId: pharmacistId,
      medicineName: name,
      type: type,
      delta: delta,
      resultingStock: updatedStock,
      reason: reason ?? (delta >= 0 ? 'Stock added' : 'Stock removed'),
    );
  }

  /// Returns the medicines that don't have enough stock to fulfil [medicines],
  /// empty if everything required is available.
  Future<List<MedicineShortfall>> checkStockAvailability(
    String pharmacistId,
    List<PrescribedMedicine> medicines,
  ) async {
    final List<MedicineInventoryItem> inventory = await getInventory(
      pharmacistId,
    );
    int availableStockOf(String name) {
      for (final MedicineInventoryItem item in inventory) {
        if (item.name == name) {
          return item.stock;
        }
      }
      return 0;
    }

    return [
      for (final PrescribedMedicine medicine in medicines)
        if (availableStockOf(medicine.name) < medicine.quantity)
          MedicineShortfall(
            medicineName: medicine.name,
            requiredQuantity: medicine.quantity,
            availableStock: availableStockOf(medicine.name),
          ),
    ];
  }

  Future<void> markDispensed(String prescriptionId, String pharmacistId) async {
    final String id = prescriptionId.trim();
    if (id.isEmpty) {
      throw ArgumentError('Prescription ID is required.');
    }

    final DocumentSnapshot<Map<String, dynamic>> doc = await _firestore
        .collection('prescriptions')
        .doc(id)
        .get();
    final Map<String, dynamic>? data = doc.data();
    if (!doc.exists || data == null) {
      throw ArgumentError('Prescription $id was not found.');
    }

    final PharmacyPrescriptionQueueItem item = _fromFirestore(
      doc.id,
      data,
      status: 'Pending',
    );

    final List<MedicineShortfall> shortfalls = await checkStockAvailability(
      pharmacistId,
      item.medicines,
    );
    if (shortfalls.isNotEmpty) {
      throw InsufficientStockException(shortfalls);
    }

    for (final PrescribedMedicine medicine in item.medicines) {
      await changeInventoryStock(
        pharmacistId,
        medicine.name,
        -medicine.quantity,
        type: InventoryTransactionType.dispensed,
        reason: 'Dispensed for prescription $id',
      );
    }

    await _firestore.collection('prescriptions').doc(id).update(
      <String, dynamic>{
        'status': PrescriptionRecord.statusDispensed,
        'dispensedAt': FieldValue.serverTimestamp(),
      },
    );
  }
}
