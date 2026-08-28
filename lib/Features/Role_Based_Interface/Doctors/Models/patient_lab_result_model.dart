/// A completed lab order as seen from the doctor's side — read-only view of
/// whatever a lab specialist attached, scoped to one patient.
class PatientLabResultModel {
  const PatientLabResultModel({
    required this.id,
    required this.orderType,
    required this.requestedBy,
    this.resultNote,
    this.resultFileName,
    this.completedAt,
  });

  final String id;
  final String orderType;
  final String requestedBy;
  final String? resultNote;
  final String? resultFileName;
  final DateTime? completedAt;
}
