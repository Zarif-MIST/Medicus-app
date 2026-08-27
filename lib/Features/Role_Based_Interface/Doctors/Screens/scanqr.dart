import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:medicus/Features/Authentication/Models/auth_account.dart';
import 'package:medicus/Features/Authentication/Models/auth_role.dart';
import 'package:medicus/Features/Authentication/Services/auth_registry.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Models/patient_record_model.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Screens/patient_detail_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Screens/prescription_form_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Services/doctor_service.dart';
import 'package:medicus/Features/Role_Based_Interface/Lab_Specialist/Screens/scanned_patient_orders_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Pharmacist/Screens/scanned_patient_queue_screen.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';

class Scanqr extends StatefulWidget {
  const Scanqr({super.key, required this.account});

  final AuthAccount account;

  @override
  State<Scanqr> createState() => _ScanqrState();
}

class _ScanqrState extends State<Scanqr> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    autoZoom: true,
  );

  bool _isHandlingScan = false;

  Future<void> _openScanAction(PatientRecordModel record) async {
    final _ScanAction? action = await showModalBottomSheet<_ScanAction>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: Text(record.account.fullName),
                  subtitle: Text('Patient ID: ${record.account.userId}'),
                ),
                const SizedBox(height: 8),
                ListTile(
                  onTap: () =>
                      Navigator.of(sheetContext).pop(_ScanAction.record),
                  leading: const Icon(Icons.folder_shared_outlined),
                  title: const Text('Open Patient Record'),
                ),
                ListTile(
                  onTap: () =>
                      Navigator.of(sheetContext).pop(_ScanAction.prescription),
                  leading: const Icon(Icons.edit_note_outlined),
                  title: const Text('Go To Prescription Form'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || action == null) {
      return;
    }

    if (action == _ScanAction.record) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PatientDetailScreen(record: record)),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            PrescriptionFormScreen(doctor: widget.account, patient: record),
      ),
    );
  }

  Future<void> _handleDetection(BarcodeCapture capture) async {
    if (_isHandlingScan) {
      return;
    }

    final String? rawValue = capture.barcodes.firstOrNull?.rawValue?.trim();
    if (rawValue == null || rawValue.isEmpty) {
      return;
    }

    setState(() => _isHandlingScan = true);
    await _controller.stop();

    if (widget.account.role == AuthRole.pharmacist) {
      await _handlePharmacistScan(rawValue);
    } else if (widget.account.role == AuthRole.labSpecialist) {
      await _handleLabScan(rawValue);
    } else {
      await _handleDoctorScan(rawValue);
    }

    if (!mounted) {
      return;
    }

    setState(() => _isHandlingScan = false);
    await _controller.start();
  }

  /// Pharmacists never get patient record or prescription-authoring access —
  /// a scan only ever resolves to that one patient's own pending
  /// prescription(s).
  Future<void> _handlePharmacistScan(String rawValue) async {
    final AuthAccount? patientAccount = await AuthRegistry.instance
        .accountForUserId(rawValue);
    if (!mounted) {
      return;
    }

    if (patientAccount == null || patientAccount.role != AuthRole.patient) {
      Get.snackbar(
        'Patient not found',
        'No patient record matched ID $rawValue.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final String pharmacistId =
        widget.account.firebaseUid ?? widget.account.userId;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScannedPatientQueueScreen(
          patientId: rawValue,
          patientName: patientAccount.fullName,
          pharmacistId: pharmacistId,
        ),
      ),
    );
  }

  /// Lab specialists never get patient record or prescription-authoring
  /// access — a scan only ever resolves to that one patient's own pending
  /// lab order(s) as given by their doctor.
  Future<void> _handleLabScan(String rawValue) async {
    final AuthAccount? patientAccount = await AuthRegistry.instance
        .accountForUserId(rawValue);
    if (!mounted) {
      return;
    }

    if (patientAccount == null || patientAccount.role != AuthRole.patient) {
      Get.snackbar(
        'Patient not found',
        'No patient record matched ID $rawValue.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScannedPatientOrdersScreen(
          patientId: rawValue,
          patientName: patientAccount.fullName,
        ),
      ),
    );
  }

  Future<void> _handleDoctorScan(String rawValue) async {
    final record = await DoctorService.instance.getPatientRecordById(rawValue);
    if (!mounted) {
      return;
    }

    if (record == null) {
      Get.snackbar(
        'Patient not found',
        'No patient record matched ID $rawValue.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    await _openScanAction(record);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF181818)
          : const Color(0xFFF6F3F1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Scan QR'),
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _handleDetection),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.45)
                          : Colors.white.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scan patient QR',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: isDark ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.account.role == AuthRole.pharmacist
                              ? 'Align the QR code inside the camera frame to view this patient\'s pending prescription.'
                              : widget.account.role == AuthRole.labSpecialist
                              ? 'Align the QR code inside the camera frame to view this patient\'s pending lab orders.'
                              : 'Align the QR code inside the camera frame to open the patient record.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: MColors.primaryColor, width: 3),
                    ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () async => _controller.toggleTorch(),
                    style: FilledButton.styleFrom(
                      backgroundColor: MColors.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    icon: const Icon(Icons.flashlight_on_outlined),
                    label: const Text('Toggle Flash'),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _ScanAction { record, prescription }
