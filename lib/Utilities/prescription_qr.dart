import 'dart:convert';

/// The QR payload printed on every prescription PDF (see
/// `Patients/Utilities/prescription_pdf.dart`) and decoded by the
/// pharmacist's scanner (see `Pharmacist/Screens/scan_prescription_screen.dart`)
/// to pull the prescription straight into their fulfillment queue.
///
/// It's self-contained (carries the full medicine list, not just an id to
/// look up) so a scan works even if the pharmacist's queue has never heard
/// of this prescription before — the same way a paper slip would. This is
/// "authenticity" in the sense of a structured, hard-to-mistype reference to
/// exactly this prescription/patient — it is not cryptographically signed,
/// so it doesn't protect against a deliberately forged QR image.
const String kPrescriptionQrType = 'medicus_rx';

class PrescriptionQrMedicine {
  const PrescriptionQrMedicine({
    required this.name,
    required this.dosage,
    required this.durationDays,
  });

  final String name;
  final String dosage;
  final int durationDays;

  Map<String, dynamic> toJson() => {'n': name, 'd': dosage, 't': durationDays};

  factory PrescriptionQrMedicine.fromJson(Map<String, dynamic> json) {
    return PrescriptionQrMedicine(
      name: json['n'] as String? ?? '',
      dosage: json['d'] as String? ?? '',
      durationDays: (json['t'] as num?)?.toInt() ?? 0,
    );
  }

  String get summary => '$name — $dosage ($durationDays d)';
}

class PrescriptionQrPayload {
  const PrescriptionQrPayload({
    required this.rxId,
    required this.patientId,
    required this.patientName,
    required this.doctorName,
    required this.issuedOn,
    required this.medicines,
  });

  final String rxId;
  final String patientId;
  final String patientName;
  final String doctorName;
  final DateTime issuedOn;
  final List<PrescriptionQrMedicine> medicines;

  String encode() {
    return jsonEncode({
      'type': kPrescriptionQrType,
      'rxId': rxId,
      'patientId': patientId,
      'patientName': patientName,
      'doctorName': doctorName,
      'issuedOn': issuedOn.toIso8601String(),
      'medicines': [for (final m in medicines) m.toJson()],
    });
  }

  /// Returns null for anything that isn't a well-formed Medicus prescription
  /// QR — a blank scan, a stray barcode, or a different app's QR entirely.
  static PrescriptionQrPayload? tryDecode(String raw) {
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic> || decoded['type'] != kPrescriptionQrType) {
        return null;
      }

      final String? rxId = decoded['rxId'] as String?;
      final String? patientId = decoded['patientId'] as String?;
      if (rxId == null || rxId.isEmpty || patientId == null || patientId.isEmpty) {
        return null;
      }

      return PrescriptionQrPayload(
        rxId: rxId,
        patientId: patientId,
        patientName: decoded['patientName'] as String? ?? '',
        doctorName: decoded['doctorName'] as String? ?? '',
        issuedOn: DateTime.tryParse(decoded['issuedOn'] as String? ?? '') ?? DateTime.now(),
        medicines: [
          for (final item in (decoded['medicines'] as List<dynamic>? ?? const []))
            PrescriptionQrMedicine.fromJson(item as Map<String, dynamic>),
        ],
      );
    } catch (_) {
      return null;
    }
  }
}
