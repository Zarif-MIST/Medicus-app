import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medicus/Features/Role_Based_Interface/Pharmacist/Models/medicine_shortfall.dart';
import 'package:medicus/Features/Role_Based_Interface/Pharmacist/Models/pharmacy_prescription_queue_item.dart';
import 'package:medicus/Features/Role_Based_Interface/Pharmacist/Services/pharmacist_service.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';

class PrescriptionFulfillmentScreen extends StatefulWidget {
  const PrescriptionFulfillmentScreen({
    super.key,
    required this.item,
    required this.pharmacistId,
  });

  final PharmacyPrescriptionQueueItem item;
  final String pharmacistId;

  @override
  State<PrescriptionFulfillmentScreen> createState() =>
      _PrescriptionFulfillmentScreenState();
}

class _PrescriptionFulfillmentScreenState
    extends State<PrescriptionFulfillmentScreen> {
  late Future<List<MedicineShortfall>> _shortfallsFuture;

  @override
  void initState() {
    super.initState();
    _shortfallsFuture = PharmacistService.instance.checkStockAvailability(
      widget.pharmacistId,
      widget.item.medicines,
    );
  }

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
      body: FutureBuilder<List<MedicineShortfall>>(
        future: _shortfallsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: MColors.primaryColor),
            );
          }

          final List<MedicineShortfall> shortfalls = snapshot.data!;
          final Map<String, MedicineShortfall> shortfallByName = {
            for (final MedicineShortfall s in shortfalls) s.medicineName: s,
          };

          return _FulfillmentBody(
            item: widget.item,
            isDark: isDark,
            shortfalls: shortfalls,
            shortfallByName: shortfallByName,
            pharmacistId: widget.pharmacistId,
          );
        },
      ),
    );
  }
}

class _FulfillmentBody extends StatefulWidget {
  const _FulfillmentBody({
    required this.item,
    required this.isDark,
    required this.shortfalls,
    required this.shortfallByName,
    required this.pharmacistId,
  });

  final PharmacyPrescriptionQueueItem item;
  final bool isDark;
  final List<MedicineShortfall> shortfalls;
  final Map<String, MedicineShortfall> shortfallByName;
  final String pharmacistId;

  @override
  State<_FulfillmentBody> createState() => _FulfillmentBodyState();
}

class _FulfillmentBodyState extends State<_FulfillmentBody> {
  /// How many units of each medicine the pharmacist has chosen to dispense
  /// this visit — defaults to everything still owed, capped by whatever's
  /// actually in stock right now (never more than either).
  late final Map<String, int> _selectedQuantities = {
    for (final medicine in widget.item.medicines)
      medicine.name: _maxSelectable(medicine),
  };

  bool _submitting = false;

  int _maxSelectable(PrescribedMedicine medicine) {
    final MedicineShortfall? shortfall = widget.shortfallByName[medicine.name];
    if (shortfall == null) return medicine.remainingQuantity;
    return shortfall.availableStock.clamp(0, medicine.remainingQuantity);
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await PharmacistService.instance.dispensePartial(
        prescriptionId: widget.item.id,
        pharmacistId: widget.pharmacistId,
        quantitiesToDispense: _selectedQuantities,
      );
    } on InsufficientStockException catch (e) {
      if (!mounted) return;
      Get.snackbar(
        'Cannot dispense',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade50,
      );
      return;
    } catch (e) {
      if (!mounted) return;
      Get.snackbar(
        'Could not dispense',
        '$e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade50,
      );
      return;
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }

    if (!mounted) return;

    final bool fullyDispensed = widget.item.medicines.every(
      (medicine) =>
          (_selectedQuantities[medicine.name] ?? 0) + medicine.dispensedQuantity >=
          medicine.quantity,
    );
    Get.snackbar(
      fullyDispensed ? 'Prescription dispensed' : 'Partially dispensed',
      fullyDispensed
          ? 'Prescription ${widget.item.id} has been fully dispensed.'
          : 'Some medicine remains on prescription ${widget.item.id} — dispense the rest on a later visit.',
      snackPosition: SnackPosition.BOTTOM,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final int totalSelected = _selectedQuantities.values.fold(0, (a, b) => a + b);
    final bool allFullyDispensedAlready = widget.item.medicines.every(
      (medicine) => medicine.isFullyDispensed,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        _Card(
          isDark: widget.isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.item.patientName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Patient ID: ${widget.item.patientId}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Text(
                'Doctor: ${widget.item.doctorName}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (widget.shortfalls.isNotEmpty) ...[
          _StockShortageBanner(shortfalls: widget.shortfalls),
          const SizedBox(height: 16),
        ],
        Text(
          'Medicines (${widget.item.medicines.length})',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          'Choose how much of each to hand over now — the patient may not want the full course at once. You can dispense the rest on a later visit.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 10),
        for (final medicine in widget.item.medicines) ...[
          _MedicineCard(
            isDark: widget.isDark,
            medicine: medicine,
            shortfall: widget.shortfallByName[medicine.name],
            maxSelectable: _maxSelectable(medicine),
            selectedQuantity: _selectedQuantities[medicine.name] ?? 0,
            onChanged: (value) =>
                setState(() => _selectedQuantities[medicine.name] = value),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 4),
        FilledButton.icon(
          onPressed: (totalSelected == 0 || _submitting) ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: MColors.primaryColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade400,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          icon: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.check_circle_outline),
          label: Text(
            allFullyDispensedAlready
                ? 'Already fully dispensed'
                : (totalSelected == 0
                      ? 'Choose a quantity to dispense'
                      : 'Dispense Selected'),
          ),
        ),
      ],
    );
  }
}

class _MedicineCard extends StatelessWidget {
  const _MedicineCard({
    required this.isDark,
    required this.medicine,
    required this.maxSelectable,
    required this.selectedQuantity,
    required this.onChanged,
    this.shortfall,
  });

  final bool isDark;
  final PrescribedMedicine medicine;
  final int maxSelectable;
  final int selectedQuantity;
  final ValueChanged<int> onChanged;
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color:
                      (hasShortfall
                              ? Colors.red.shade700
                              : MColors.primaryColor)
                          .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  medicine.dispensedQuantity > 0
                      ? '${medicine.dispensedQuantity}/${medicine.quantity} given'
                      : 'Qty ${medicine.quantity}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: hasShortfall
                        ? Colors.red.shade700
                        : MColors.primaryColor,
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
              _MedicineDetail(
                icon: Icons.medication_outlined,
                label: medicine.dosage,
              ),
              _MedicineDetail(
                icon: Icons.schedule_outlined,
                label: medicine.frequency,
              ),
              _MedicineDetail(
                icon: Icons.event_repeat_outlined,
                label: medicine.duration,
              ),
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
                  Icon(
                    Icons.error_outline,
                    size: 16,
                    color: Colors.red.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      shortfall!.isOutOfStock
                          ? 'Out of stock in inventory'
                          : 'Only ${shortfall!.availableStock} in stock — ${shortfall!.requiredQuantity} still owed on this course',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (medicine.instructions != null &&
              medicine.instructions!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF262626)
                    : const Color(0xFFF3F1EF),
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
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (medicine.isFullyDispensed)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  'Fully dispensed',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            )
          else
            _QuantityStepper(
              label: 'Dispense now',
              value: selectedQuantity,
              max: maxSelectable,
              onChanged: onChanged,
            ),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$label (max $max)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ),
        IconButton(
          onPressed: value > 0 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
          color: MColors.primaryColor,
          visualDensity: VisualDensity.compact,
        ),
        SizedBox(
          width: 32,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
          color: MColors.primaryColor,
          visualDensity: VisualDensity.compact,
        ),
      ],
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
        Text(label, style: Theme.of(context).textTheme.bodySmall),
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
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1.2)
            : null,
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
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w700,
                  ),
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
