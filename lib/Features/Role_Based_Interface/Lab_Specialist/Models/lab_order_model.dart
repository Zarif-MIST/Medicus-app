import 'dart:convert';
import 'dart:typed_data';

/// The fixed set of test types a lab specialist can register under (their
/// one specialty, e.g. "X-Ray") and a doctor can pick when recommending a
/// test — the single source of truth for both, so a test a doctor can order
/// always corresponds to a specialty a lab specialist actually has.
const List<String> kLabTestTypes = [
  'X-Ray',
  'CT Scan',
  'MRI',
  'Ultrasound (USG)',
  'ECG',
  'Pathology (Blood Test)',
  'Endoscopy',
];

class LabOrderModel {
  const LabOrderModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.orderType,
    required this.requestedBy,
    required this.status,
    this.prescriptionId = '',
    this.createdAt,
    this.completedAt,
    this.resultNote,
    this.resultFileName,
    this.resultFileBase64,
  });

  final String id;
  final String patientId;
  final String patientName;
  final String orderType;
  final String requestedBy;
  final String status;

  /// The prescription this test was recommended from, if any — empty for
  /// standalone orders not tied to a specific prescription.
  final String prescriptionId;
  final DateTime? createdAt;
  final DateTime? completedAt;
  final String? resultNote;

  /// Display name of the attached result photo (e.g. "chest_xray.jpg") —
  /// just a label; the actual image lives in [resultFileBase64].
  final String? resultFileName;

  /// The attached result photo's bytes, inline-encoded (same "no Storage
  /// bucket needed" approach as [LabReportService]) — null if no file was
  /// attached, or if this order predates result-file storage being added.
  final String? resultFileBase64;

  Uint8List? get resultImageBytes =>
      resultFileBase64 == null ? null : base64Decode(resultFileBase64!);
}
