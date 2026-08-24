import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medicus/Features/Role_Based_Interface/Pharmacist/Models/pharmacy_prescription_queue_item.dart';
import 'package:medicus/Features/Role_Based_Interface/Pharmacist/Services/pharmacist_service.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';

class PrescriptionFulfillmentScreen extends StatelessWidget {
  const PrescriptionFulfillmentScreen({super.key, required this.item});

  final PharmacyPrescriptionQueueItem item;

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF181818)
          : const Color(0xFFF7F5F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Prescription Detail'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          _Card(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.patientName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Patient ID: ${item.patientId}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Text(
                  'Doctor: ${item.doctorName}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'Medicines',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                for (final medicine in item.medicines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '• $medicine',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () async {
              try {
                await PharmacistService.instance.markDispensed(item.id);
              } catch (e) {
                if (context.mounted) {
                  Get.snackbar('Could not mark dispensed', '$e', snackPosition: SnackPosition.BOTTOM);
                }
                return;
              }
              if (!context.mounted) {
                return;
              }
              Get.snackbar(
                'Marked dispensed',
                'Prescription ${item.id} has been marked as dispensed.',
                snackPosition: SnackPosition.BOTTOM,
              );
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: MColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Mark as Dispensed'),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.isDark, required this.child});

  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
