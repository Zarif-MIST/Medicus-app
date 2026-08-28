import 'package:flutter/material.dart';
import 'package:medicus/Features/Role_Based_Interface/Pharmacist/Models/pharmacy_prescription_queue_item.dart';
import 'package:medicus/Features/Role_Based_Interface/Pharmacist/Screens/prescription_fulfillment_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Pharmacist/Services/pharmacist_service.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';

/// Shown after a pharmacist scans a patient's QR code. Scoped strictly to
/// that one patient's pending prescription(s) — no other patient data,
/// medical history, or prescription-writing capability is reachable here.
class ScannedPatientQueueScreen extends StatefulWidget {
  const ScannedPatientQueueScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.pharmacistId,
  });

  final String patientId;
  final String patientName;
  final String pharmacistId;

  @override
  State<ScannedPatientQueueScreen> createState() =>
      _ScannedPatientQueueScreenState();
}

class _ScannedPatientQueueScreenState extends State<ScannedPatientQueueScreen> {
  late Future<List<PharmacyPrescriptionQueueItem>> _pendingFuture;

  @override
  void initState() {
    super.initState();
    _pendingFuture = _load();
  }

  Future<List<PharmacyPrescriptionQueueItem>> _load() {
    return PharmacistService.instance.getPendingPrescriptionsForPatient(
      widget.patientId,
    );
  }

  Future<void> _openFulfillment(PharmacyPrescriptionQueueItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PrescriptionFulfillmentScreen(
          item: item,
          pharmacistId: widget.pharmacistId,
        ),
      ),
    );
    setState(() {
      _pendingFuture = _load();
    });
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
        title: Text(
          widget.patientName.isEmpty ? 'Patient' : widget.patientName,
        ),
      ),
      body: FutureBuilder<List<PharmacyPrescriptionQueueItem>>(
        future: _pendingFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: MColors.primaryColor),
            );
          }

          final List<PharmacyPrescriptionQueueItem> items = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.24 : 0.05,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: MColors.primaryColor.withValues(
                        alpha: 0.12,
                      ),
                      child: const Icon(
                        Icons.badge_outlined,
                        color: MColors.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.patientName.isEmpty
                                ? 'Patient'
                                : widget.patientName,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Patient ID: ${widget.patientId}',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Pending prescriptions (${items.length})',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 10),
              if (items.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 26,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This patient has no pending prescription right now.',
                        textAlign: TextAlign.center,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              else
                for (final item in items) ...[
                  _ScannedPrescriptionCard(
                    item: item,
                    isDark: isDark,
                    onFulfill: () => _openFulfillment(item),
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _ScannedPrescriptionCard extends StatelessWidget {
  const _ScannedPrescriptionCard({
    required this.item,
    required this.isDark,
    required this.onFulfill,
  });

  final PharmacyPrescriptionQueueItem item;
  final bool isDark;
  final VoidCallback onFulfill;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dr. ${item.doctorName}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          for (final medicine in item.medicines)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle, size: 5, color: Colors.grey.shade400),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: medicine.name,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(
                            text:
                                '  ${medicine.dosage} • ${medicine.frequency}',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: MColors.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '×${medicine.quantity}',
                      style: TextStyle(
                        color: MColors.primaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: onFulfill,
              style: FilledButton.styleFrom(
                backgroundColor: MColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                minimumSize: const Size(0, 34),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              icon: const Icon(Icons.arrow_forward, size: 15),
              label: const Text('Review'),
            ),
          ),
        ],
      ),
    );
  }
}
