import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:medicus/Features/Authentication/Models/auth_account.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Screens/patient_detail_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Services/doctor_service.dart';
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

    final record = await DoctorService.instance.getPatientRecordById(rawValue);
    if (!mounted) {
      return;
    }

    if (record == null) {
      setState(() => _isHandlingScan = false);
      await _controller.start();
      if (!mounted) {
        return;
      }
      Get.snackbar(
        'Patient not found',
        'No patient record matched ID $rawValue.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PatientDetailScreen(record: record, doctor: widget.account)),
    );

    if (!mounted) {
      return;
    }

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
                          'Align the QR code inside the camera frame to open the patient record.',
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
