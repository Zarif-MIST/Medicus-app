import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicus/Features/Role_Based_Interface/Lab_Specialist/Models/lab_order_model.dart';

class LabService {
  LabService._();

  static final LabService instance = LabService._();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('lab_orders');

  Future<List<LabOrderModel>> getPendingOrders() async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _orders
        .where('status', isNotEqualTo: 'Completed')
        .get();
    final List<LabOrderModel> orders = [
      for (final doc in snapshot.docs) _fromFirestore(doc.id, doc.data()),
    ];
    orders.sort((a, b) {
      final DateTime aTime =
          a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime bTime =
          b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return orders;
  }

  Future<List<LabOrderModel>> getPendingOrdersForPatient(
    String patientId,
  ) async {
    final String id = patientId.trim();
    if (id.isEmpty) {
      return const [];
    }

    final QuerySnapshot<Map<String, dynamic>> snapshot = await _orders
        .where('patientId', isEqualTo: id)
        .get();
    final List<LabOrderModel> orders = [
      for (final doc in snapshot.docs) _fromFirestore(doc.id, doc.data()),
    ];
    return orders.where((order) => order.status != 'Completed').toList();
  }

  Future<List<LabOrderModel>> getAllOrders() async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _orders.get();
    final List<LabOrderModel> orders = [
      for (final doc in snapshot.docs) _fromFirestore(doc.id, doc.data()),
    ];
    orders.sort((a, b) {
      final DateTime aTime =
          (a.completedAt ?? a.createdAt) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime bTime =
          (b.completedAt ?? b.createdAt) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return orders;
  }

  Future<void> attachResult({
    required String orderId,
    required String note,
    String? fileName,
  }) async {
    final String id = orderId.trim();
    if (id.isEmpty) {
      throw ArgumentError('Order ID is required.');
    }

    await _orders.doc(id).update(<String, dynamic>{
      'status': 'Completed',
      'resultNote': note,
      'resultFileName': fileName,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  LabOrderModel _fromFirestore(String id, Map<String, dynamic> data) {
    final Object? rawCreatedAt = data['createdAt'];
    final Object? rawCompletedAt = data['completedAt'];
    return LabOrderModel(
      id: id,
      patientId: (data['patientId'] ?? '').toString(),
      patientName: (data['patientName'] ?? '').toString(),
      orderType: (data['orderType'] ?? '').toString(),
      requestedBy: (data['requestedBy'] ?? '').toString(),
      status: (data['status'] ?? 'Pending').toString(),
      createdAt: rawCreatedAt is Timestamp ? rawCreatedAt.toDate() : null,
      completedAt: rawCompletedAt is Timestamp ? rawCompletedAt.toDate() : null,
      resultNote: data['resultNote'] as String?,
      resultFileName: data['resultFileName'] as String?,
    );
  }
}
