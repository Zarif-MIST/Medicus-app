import 'package:flutter/material.dart';
import 'package:medicus/Features/Role_Based_Interface/Pharmacist/Models/inventory_transaction.dart';
import 'package:medicus/Features/Role_Based_Interface/Pharmacist/Services/pharmacist_service.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';

class InventoryLogScreen extends StatefulWidget {
  const InventoryLogScreen({super.key, required this.pharmacistId});

  final String pharmacistId;

  @override
  State<InventoryLogScreen> createState() => _InventoryLogScreenState();
}

class _InventoryLogScreenState extends State<InventoryLogScreen> {
  late Future<List<InventoryTransaction>> _logFuture;

  @override
  void initState() {
    super.initState();
    _logFuture = PharmacistService.instance.getInventoryLog(
      widget.pharmacistId,
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
        title: const Text('Inventory Log'),
      ),
      body: FutureBuilder<List<InventoryTransaction>>(
        future: _logFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: MColors.primaryColor),
            );
          }

          final List<InventoryTransaction> transactions = snapshot.data!;

          if (transactions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No inventory transactions yet. Stock changes, restocks, and dispensing will show up here.',
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
            itemCount: transactions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _TransactionTile(
              isDark: isDark,
              transaction: transactions[index],
            ),
          );
        },
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.isDark, required this.transaction});

  final bool isDark;
  final InventoryTransaction transaction;

  ({IconData icon, Color color}) get _style {
    switch (transaction.type) {
      case InventoryTransactionType.dispensed:
        return (
          icon: Icons.local_pharmacy_outlined,
          color: Colors.orange.shade700,
        );
      case InventoryTransactionType.restock:
        return (icon: Icons.add_box_outlined, color: Colors.green.shade700);
      case InventoryTransactionType.adjustment:
        return (
          icon: Icons.tune,
          color: transaction.delta >= 0
              ? Colors.green.shade700
              : Colors.red.shade700,
        );
      case InventoryTransactionType.added:
        return (icon: Icons.new_releases_outlined, color: MColors.primaryColor);
      case InventoryTransactionType.removed:
        return (icon: Icons.delete_outline, color: Colors.red.shade700);
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final String hour = (timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12)
        .toString();
    final String minute = timestamp.minute.toString().padLeft(2, '0');
    final String period = timestamp.hour < 12 ? 'AM' : 'PM';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} • $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final ({IconData icon, Color color}) style = _style;
    final bool isPositive = transaction.delta >= 0;

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
            backgroundColor: style.color.withValues(alpha: 0.14),
            child: Icon(style.icon, color: style.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.medicineName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  transaction.reason,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(transaction.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isPositive ? '+' : ''}${transaction.delta}',
                style: TextStyle(
                  color: style.color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${transaction.resultingStock} left',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
