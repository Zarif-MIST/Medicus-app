class LabOrderModel {
  const LabOrderModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.orderType,
    required this.requestedBy,
    required this.status,
    this.createdAt,
    this.completedAt,
    this.resultNote,
    this.resultFileName,
  });

  final String id;
  final String patientId;
  final String patientName;
  final String orderType;
  final String requestedBy;
  final String status;
  final DateTime? createdAt;
  final DateTime? completedAt;
  final String? resultNote;
  final String? resultFileName;
}
