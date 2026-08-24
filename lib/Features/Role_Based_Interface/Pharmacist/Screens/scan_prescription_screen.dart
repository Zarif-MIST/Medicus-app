import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:medicus/Features/Prescriptions/Services/prescription_repository.dart';
import 'package:medicus/Features/Role_Based_Interface/Pharmacist/Models/pharmacy_prescription_queue_item.dart';
import 'package:medicus/Features/Role_Based_Interface/Pharmacist/Screens/prescription_fulfillment_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Pharmacist/Services/pharmacist_service.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';
import 'package:medicus/Utilities/prescription_qr.dart';

/// Scans the QR printed on a patient's prescription PDF and pulls it
/// straight into the pharmacist's fulfillment queue — the "collect medicine"
/// counterpart to the doctor's patient-record scanner.
class ScanPrescriptionScreen extends StatefulWidget {
  const ScanPrescriptionScreen({super.key});

  @override
  State<ScanPrescriptionScreen> createState() => _ScanPrescriptionScreenState();
}

class _ScanPrescriptionScreenState extends State<ScanPrescriptionScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    autoZoom: true,
  );

  bool _isHandlingScan = false;

  Future<void> _handleDetection(BarcodeCapture capture) async {
    if (_isHandlingScan) return;

    final String? rawValue = capture.barcodes.firstOrNull?.rawValue?.trim();
    if (rawValue == null || rawValue.isEmpty) return;

    final PrescriptionQrPayload? payload = PrescriptionQrPayload.tryDecode(rawValue);
    if (payload == null) {
      Get.snackbar(
        'Not a prescription QR',
        'This code isn\'t a Medicus prescription — try another.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _isHandlingScan = true);
    await _controller.stop();

    PharmacyPrescriptionQueueItem? item;
    String? errorMessage;
    try {
      item = await PharmacistService.instance.receiveScannedPrescription(payload);
    } on PrescriptionNotFoundException {
      errorMessage = 'No prescription on file for that QR — it may not have been issued yet.';
    } on PrescriptionVerificationException {
      errorMessage = "This QR's patient details don't match our record for that prescription.";
    } catch (e) {
      errorMessage = 'Could not verify this prescription: $e';
    }

    if (!mounted) return;

    if (item == null) {
      Get.snackbar('Not verified', errorMessage!, snackPosition: SnackPosition.BOTTOM);
      setState(() => _isHandlingScan = false);
      await _controller.start();
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PrescriptionFulfillmentScreen(item: item!)),
    );

    if (!mounted) return;
    setState(() => _isHandlingScan = false);
    await _controller.start();
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
      backgroundColor: isDark ? const Color(0xFF181818) : const Color(0xFFF6F3F1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Scan Prescription'),
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
                      color: isDark ? Colors.black.withValues(alpha: 0.45) : Colors.white.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scan prescription QR',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: isDark ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Align the QR code from the patient\'s prescription printout inside the frame.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
