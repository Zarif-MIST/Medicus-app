import 'package:medicus/Features/Role_Based_Interface/Lab_Specialist/Models/lab_order_model.dart';

class LabService {
  LabService._();

  static final LabService instance = LabService._();

  Future<List<LabOrderModel>> getPendingOrders() async {
    // TODO(firebase): replace mock lab orders with Firestore-backed pending lab/imaging requests.
    return const <LabOrderModel>[
      LabOrderModel(
        id: 'LAB-301',
        patientId: '4821',
        patientName: 'Tareq Hasan',
        orderType: 'CBC + Blood Sugar',
        requestedBy: 'Dr. Farhana Rahman',
        status: 'Pending',
      ),
      LabOrderModel(
        id: 'LAB-302',
        patientId: '6108',
        patientName: 'Nafis Ahmed',
        orderType: 'Chest X-Ray',
        requestedBy: 'Dr. Nusrat Jahan',
        status: 'Completed',
      ),
    ];
  }

  Future<void> attachResult({
    required String orderId,
    required String note,
  }) async {
    // TODO(firebase): upload/attach lab result metadata and files to Firestore/Storage.
    if (orderId.trim().isEmpty) {
      throw ArgumentError('Order ID is required.');
    }
  }
}
