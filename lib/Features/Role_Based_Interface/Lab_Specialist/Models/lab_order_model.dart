class LabOrderModel {
  const LabOrderModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.orderType,
    required this.requestedBy,
    required this.status,
  });

  final String id;
  final String patientId;
  final String patientName;
  final String orderType;
  final String requestedBy;
  final String status;
}
