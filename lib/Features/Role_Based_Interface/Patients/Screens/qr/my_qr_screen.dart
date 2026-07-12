import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:medicus/Utilities/colors.dart';

/// Displays the patient's treatment QR code for a doctor to scan.
///
/// Currently encodes a placeholder token — wiring this to a real,
/// short-lived session issued by a Core `qr_session_service` (Firestore
/// backed) is future work once the doctor-side scanner is built.
class MyQrScreen extends StatelessWidget {
  const MyQrScreen({super.key, required this.patientId, required this.patientName});

  final String patientId;
  final String patientName;

  @override
  Widget build(BuildContext context) {
    final String qrData = 'MEDICUS-PATIENT-$patientId';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Treatment QR'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                patientName,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Patient ID: $patientId',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 220,
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: MColors.primaryColor),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Show this code to your doctor to link this visit\nto your medical record.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
