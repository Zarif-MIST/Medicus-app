import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medicus/Features/Role_Based_Interface/Pharmacist/Models/medicine_shortfall.dart';
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
    final List<MedicineShortfall> shortfalls =
        PharmacistService.instance.checkStockAvailability(item.medicines);
    final Map<String, MedicineShortfall> shortfallByName = {
      for (final MedicineShortfall s in shortfalls) s.medicineName: s,
    };
    final bool canDispense = shortfalls.isEmpty;

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
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!canDispense) ...[
            _StockShortageBanner(shortfalls: shortfalls),
            const SizedBox(height: 16),
          ],
          Text(
            'Medicines (${item.medicines.length})',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 10),
          for (final medicine in item.medicines) ...[
            _MedicineCard(
              isDark: isDark,
              medicine: medicine,
              shortfall: shortfallByName[medicine.name],
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 4),
          FilledButton.icon(
            onPressed: !canDispense
                ? null
                : () async {
                    try {
                      await PharmacistService.instance.markDispensed(item.id);
                    } on InsufficientStockException catch (e) {
                      if (!context.mounted) {
                        return;
                      }
                      Get.snackbar(
                        'Cannot dispense',
                        e.message,
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.red.shade50,
                      );
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
              disabledBackgroundColor: Colors.grey.shade400,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.check_circle_outline),
            label: Text(canDispense ? 'Mark as Dispensed' : 'Insufficient stock to dispense'),
          ),
        ],
      ),
    );
  }
}

class _MedicineCard extends StatelessWidget {
  const _MedicineCard({
    required this.isDark,
    required this.medicine,
    this.shortfall,
  });

  final bool isDark;
  final PrescribedMedicine medicine;
  final MedicineShortfall? shortfall;

  @override
  Widget build(BuildContext context) {
    final bool hasShortfall = shortfall != null;

    return _Card(
      isDark: isDark,
      borderColor: hasShortfall ? Colors.red.shade300 : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  medicine.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (hasShortfall ? Colors.red.shade700 : MColors.primaryColor)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Qty ${medicine.quantity}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: hasShortfall ? Colors.red.shade700 : MColors.primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _MedicineDetail(icon: Icons.medication_outlined, label: medicine.dosage),
              _MedicineDetail(icon: Icons.schedule_outlined, label: medicine.frequency),
              _MedicineDetail(icon: Icons.event_repeat_outlined, label: medicine.duration),
            ],
          ),
          if (hasShortfall) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline, size: 16, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      shortfall!.isOutOfStock
                          ? 'Out of stock in inventory'
                          : 'Only ${shortfall!.availableStock} in stock — need ${shortfall!.requiredQuantity}',
                      style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (medicine.instructions != null && medicine.instructions!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF262626) : const Color(0xFFF3F1EF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      medicine.instructions!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MedicineDetail extends StatelessWidget {
  const _MedicineDetail({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: MColors.primaryColor),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.isDark, required this.child, this.borderColor});

  final bool isDark;
  final Widget child;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: borderColor != null ? Border.all(color: borderColor!, width: 1.2) : null,
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

class _StockShortageBanner extends StatelessWidget {
  const _StockShortageBanner({required this.shortfalls});

  final List<MedicineShortfall> shortfalls;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cannot dispense — insufficient stock',
                  style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  shortfalls
                      .map((MedicineShortfall s) => s.medicineName)
                      .join(', '),
                  style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
