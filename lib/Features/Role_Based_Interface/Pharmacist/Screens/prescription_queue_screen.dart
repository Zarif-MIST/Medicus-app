import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medicus/Features/Role_Based_Interface/Pharmacist/Models/pharmacy_prescription_queue_item.dart';
import 'package:medicus/Features/Role_Based_Interface/Pharmacist/Screens/prescription_fulfillment_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Pharmacist/Services/pharmacist_service.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';

class PrescriptionQueueScreen extends StatefulWidget {
  const PrescriptionQueueScreen({super.key});

  @override
  State<PrescriptionQueueScreen> createState() =>
      _PrescriptionQueueScreenState();
}

class _PrescriptionQueueScreenState extends State<PrescriptionQueueScreen> {
  late Future<_QueueData> _queueFuture;

  @override
  void initState() {
    super.initState();
    _queueFuture = _loadQueueData();
  }

  Future<_QueueData> _loadQueueData() async {
    final results = await Future.wait<List<PharmacyPrescriptionQueueItem>>([
      PharmacistService.instance.getPendingPrescriptions(),
      PharmacistService.instance.getDispensedPrescriptions(),
    ]);

    return _QueueData(
      pending: results[0],
      dispensed: results[1],
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
        title: const Text('Prescription Queue'),
      ),
      body: FutureBuilder<List<PharmacyPrescriptionQueueItem>>(
        future: _queueFuture.then((value) => value.pending),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: MColors.primaryColor),
            );
          }

          return FutureBuilder<_QueueData>(
            future: _queueFuture,
            builder: (context, queueSnapshot) {
              if (!queueSnapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: MColors.primaryColor),
                );
              }

              final queueData = queueSnapshot.data!;

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                children: [
                  Text(
                    'Pending Prescriptions',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  for (final item in queueData.pending) ...[
                    _QueueCard(
                      item: item,
                      isDark: isDark,
                      onFulfill: () async {
                        await Get.to(
                          () => PrescriptionFulfillmentScreen(item: item),
                          transition: Transition.fadeIn,
                        );
                        if (!context.mounted) {
                          return;
                        }
                        setState(() {
                          _queueFuture = _loadQueueData();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (queueData.pending.isEmpty)
                    _EmptyState(
                      message: 'No pending prescriptions right now.',
                      isDark: isDark,
                    ),
                  const SizedBox(height: 18),
                  Text(
                    'Dispensed Log',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  if (queueData.dispensed.isEmpty)
                    _EmptyState(
                      message: 'No dispensed prescriptions yet.',
                      isDark: isDark,
                    )
                  else
                    for (final item in queueData.dispensed) ...[
                      _QueueCard(
                        item: item,
                        isDark: isDark,
                        showFulfillButton: false,
                        trailingColor: Colors.green,
                      ),
                      const SizedBox(height: 12),
                    ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _QueueData {
  const _QueueData({required this.pending, required this.dispensed});

  final List<PharmacyPrescriptionQueueItem> pending;
  final List<PharmacyPrescriptionQueueItem> dispensed;
}

class _QueueCard extends StatelessWidget {
  const _QueueCard({
    required this.item,
    required this.isDark,
    this.onFulfill,
    this.showFulfillButton = true,
    this.trailingColor = MColors.primaryColor,
  });

  final PharmacyPrescriptionQueueItem item;
  final bool isDark;
  final VoidCallback? onFulfill;
  final bool showFulfillButton;
  final Color trailingColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.patientName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                item.status,
                style: TextStyle(
                  color: trailingColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Prescription: ${item.id} • Doctor: ${item.doctorName}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            item.medicines.join(', '),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (showFulfillButton) ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: onFulfill,
                style: FilledButton.styleFrom(
                  backgroundColor: MColors.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('View'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, required this.isDark});

  final String message;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
      ),
    );
  }
}
