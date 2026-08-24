import 'package:medicus/Features/Prescriptions/Models/prescription_record.dart';
import 'package:medicus/Features/Prescriptions/Services/prescription_repository.dart';
import 'package:medicus/Features/Role_Based_Interface/Pharmacist/Models/pharmacy_prescription_queue_item.dart';
import 'package:medicus/Utilities/prescription_qr.dart';

class PharmacistService {
  PharmacistService._();

  static final PharmacistService instance = PharmacistService._();

  static const PrescriptionRepository _repository = PrescriptionRepository();

  PharmacyPrescriptionQueueItem _toQueueItem(PrescriptionRecord record) {
    return PharmacyPrescriptionQueueItem(
      id: record.id,
      patientId: record.patientId,
      patientName: record.patientName,
      doctorName: record.doctorName,
      status: record.status,
      medicines: [for (final m in record.medicines) m.instructions.isEmpty ? '${m.name} — ${m.dosage}' : '${m.name} — ${m.dosage} (${m.instructions})'],
    );
  }

  Future<List<PharmacyPrescriptionQueueItem>> getPendingPrescriptions() async {
    final records = await _repository.fetchByStatus(PrescriptionRecord.statusPending);
    return [for (final record in records) _toQueueItem(record)];
  }

  Future<List<PharmacyPrescriptionQueueItem>> getDispensedPrescriptions() async {
    final records = await _repository.fetchByStatus(PrescriptionRecord.statusDispensed);
    return [for (final record in records) _toQueueItem(record)];
  }

  Future<int> getDispensedTodayCount() async {
    final records = await _repository.fetchByStatus(PrescriptionRecord.statusDispensed);
    final DateTime today = DateTime.now();
    return records.where((record) {
      final DateTime? dispensedAt = record.dispensedAt;
      if (dispensedAt == null) return false;
      return dispensedAt.year == today.year && dispensedAt.month == today.month && dispensedAt.day == today.day;
    }).length;
  }

  Future<List<MedicineInventoryItem>> getInventory() async {
    // TODO(firebase): replace mock inventory with Firestore or supplier-backed medicine inventory data.
    return const <MedicineInventoryItem>[
      MedicineInventoryItem(
        name: 'Metformin 500mg',
        stock: 120,
        supplier: 'Square Pharma',
      ),
      MedicineInventoryItem(
        name: 'Amoxicillin 250mg',
        stock: 64,
        supplier: 'Beximco Pharma',
      ),
      MedicineInventoryItem(
        name: 'Cetirizine 10mg',
        stock: 89,
        supplier: 'Incepta',
      ),
    ];
  }

  /// Called when the pharmacist scans a prescription's QR (see
  /// [PrescriptionQrPayload]). The QR only carries a convenience copy of the
  /// prescription — this looks the id up on Firestore (the real record) and
  /// cross-checks the patient identity, so a scan is only accepted when it
  /// verifies against what the doctor actually filed. Throws
  /// [PrescriptionNotFoundException] or [PrescriptionVerificationException]
  /// otherwise — callers should not treat those as "added to queue".
  Future<PharmacyPrescriptionQueueItem> receiveScannedPrescription(PrescriptionQrPayload payload) async {
    final PrescriptionRecord record = await _repository.verifyScan(
      rxId: payload.rxId,
      patientId: payload.patientId,
    );
    return _toQueueItem(record);
  }

  Future<void> markDispensed(String prescriptionId) async {
    if (prescriptionId.trim().isEmpty) {
      throw ArgumentError('Prescription ID is required.');
    }
    await _repository.markDispensed(prescriptionId.trim());
  }
}
