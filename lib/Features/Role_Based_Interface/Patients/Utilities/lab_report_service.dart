import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image/image.dart' as img;

/// One uploaded report photo — the digital replacement for a handwritten
/// report the patient used to bring in on paper. The image is stored inline
/// on the Firestore document (base64), not in Cloud Storage, so this works
/// on Firebase's free Spark plan with no bucket to provision.
class LabReport {
  const LabReport({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.label,
    required this.imageBase64,
    required this.uploadedAt,
  });

  final String id;
  final String patientId;
  final String patientName;
  final String label;
  final String imageBase64;
  final DateTime uploadedAt;

  Uint8List get imageBytes => base64Decode(imageBase64);

  factory LabReport.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return LabReport(
      id: doc.id,
      patientId: data['patientId'] as String,
      patientName: data['patientName'] as String? ?? '',
      label: data['label'] as String? ?? 'Report',
      imageBase64: data['imageBase64'] as String,
      uploadedAt: (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Thrown when a picked image can't be compressed under [LabReportService.maxEncodedBytes].
class LabReportTooLargeException implements Exception {
  const LabReportTooLargeException();
}

/// Stores/retrieves patient-uploaded report photos. A registered doctor
/// looks a patient up by the same `patientId` this is keyed on (the QR /
/// AuthAccount `userId`), so a report uploaded here shows up on that
/// patient's real chart on the doctor side.
class LabReportService {
  const LabReportService();

  /// Firestore documents are capped at ~1 MiB; stay well under that once
  /// base64 overhead (~33%) and metadata are added.
  static const int maxEncodedBytes = 700 * 1024;

  CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance.collection('lab_reports');

  /// Resizes/re-encodes [rawBytes] so the base64 payload fits comfortably in
  /// a Firestore document. Throws [LabReportTooLargeException] if even the
  /// most aggressive pass can't get it under the limit.
  String _compressToBase64(Uint8List rawBytes) {
    final img.Image? decoded = img.decodeImage(rawBytes);
    if (decoded == null) {
      throw const LabReportTooLargeException();
    }

    for (final int maxDimension in [1000, 700, 500]) {
      final img.Image resized = decoded.width > maxDimension || decoded.height > maxDimension
          ? img.copyResize(
              decoded,
              width: decoded.width >= decoded.height ? maxDimension : null,
              height: decoded.height > decoded.width ? maxDimension : null,
            )
          : decoded;

      for (final int quality in [70, 50, 35]) {
        final Uint8List encoded = img.encodeJpg(resized, quality: quality);
        final String base64Str = base64Encode(encoded);
        if (base64Str.length <= maxEncodedBytes) {
          return base64Str;
        }
      }
    }

    throw const LabReportTooLargeException();
  }

  Future<void> upload({
    required String patientId,
    required String patientName,
    required String label,
    required Uint8List imageBytes,
  }) async {
    final String base64Image = _compressToBase64(imageBytes);

    await _collection.add({
      'patientId': patientId,
      'patientName': patientName,
      'label': label.trim().isEmpty ? 'Report' : label.trim(),
      'imageBase64': base64Image,
      'uploadedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<LabReport>> fetchForPatient(String patientId) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _collection.where('patientId', isEqualTo: patientId).get();

    final List<LabReport> reports = snapshot.docs.map(LabReport.fromDoc).toList()
      ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    return reports;
  }

  Future<void> delete(String reportId) => _collection.doc(reportId).delete();
}
