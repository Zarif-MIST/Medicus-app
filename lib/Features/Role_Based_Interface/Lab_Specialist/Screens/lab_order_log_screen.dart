import 'package:flutter/material.dart';
import 'package:medicus/Features/Role_Based_Interface/Lab_Specialist/Models/lab_order_model.dart';
import 'package:medicus/Features/Role_Based_Interface/Lab_Specialist/Services/lab_service.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';

/// Read-only record of every lab order — pending and completed — opened
/// from the Home screen's "Order Log" card.
class LabOrderLogScreen extends StatefulWidget {
  const LabOrderLogScreen({super.key});

  @override
  State<LabOrderLogScreen> createState() => _LabOrderLogScreenState();
}

class _LabOrderLogScreenState extends State<LabOrderLogScreen> {
  late Future<List<LabOrderModel>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = LabService.instance.getAllOrders();
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
        title: const Text('Order Log'),
      ),
      body: FutureBuilder<List<LabOrderModel>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: MColors.primaryColor),
            );
          }

          final List<LabOrderModel> orders = snapshot.data!;

          if (orders.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No lab orders recorded yet.',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) =>
                _OrderLogTile(isDark: isDark, order: orders[index]),
          );
        },
      ),
    );
  }
}

const List<String> _kMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _formatDateTime(DateTime timestamp) {
  final int hour = timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12;
  final String minute = timestamp.minute.toString().padLeft(2, '0');
  final String period = timestamp.hour < 12 ? 'AM' : 'PM';
  return '${timestamp.day} ${_kMonths[timestamp.month - 1]} ${timestamp.year}, $hour:$minute $period';
}

class _OrderLogTile extends StatelessWidget {
  const _OrderLogTile({required this.isDark, required this.order});

  final bool isDark;
  final LabOrderModel order;

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = order.status == 'Completed';
    final Color statusColor = isCompleted
        ? Colors.green
        : Colors.orange.shade700;
    final DateTime? displayTime = isCompleted
        ? (order.completedAt ?? order.createdAt)
        : order.createdAt;

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: statusColor.withValues(alpha: 0.14),
            child: Icon(
              isCompleted ? Icons.check_circle : Icons.pending_actions_outlined,
              color: statusColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.patientName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  'Patient ID: ${order.patientId} • ${order.orderType}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  order.requestedBy,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                ),
                if (displayTime != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    isCompleted
                        ? 'Completed ${_formatDateTime(displayTime)}'
                        : 'Ordered ${_formatDateTime(displayTime)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade400,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              order.status,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
