import 'package:flutter/material.dart';
import 'package:medicus/Features/Authentication/Models/auth_account.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Widgets/LiquidSearchBar.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Widgets/customShapes.dart';
import 'package:medicus/Features/Role_Based_Interface/Pharmacist/Models/pharmacy_prescription_queue_item.dart';
import 'package:medicus/Features/Role_Based_Interface/Pharmacist/Screens/inventory_log_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Pharmacist/Screens/prescription_fulfillment_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Pharmacist/Services/pharmacist_service.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';

class PharmacistHomeScreen extends StatefulWidget {
  const PharmacistHomeScreen({
    super.key,
    required this.account,
    required this.onOpenInventory,
  });

  final AuthAccount account;
  final VoidCallback onOpenInventory;

  @override
  State<PharmacistHomeScreen> createState() => PharmacistHomeScreenState();
}

class PharmacistHomeScreenState extends State<PharmacistHomeScreen> {
  late Future<_HomeQueueData> _queueFuture;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _queueFuture = _loadQueueData();
  }

  void refreshQueueData() {
    setState(() {
      _queueFuture = _loadQueueData();
    });
  }

  Future<_HomeQueueData> _loadQueueData() async {
    final results = await (
      PharmacistService.instance.getPendingPrescriptions(),
      PharmacistService.instance.getDispensedPrescriptions(),
      PharmacistService.instance.getLowStockItems(),
      PharmacistService.instance.getInventoryLog(),
    ).wait;

    return _HomeQueueData(
      pending: results.$1,
      dispensed: results.$2,
      lowStock: results.$3,
      logCount: results.$4.length,
    );
  }

  Future<void> _openInventoryLog() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const InventoryLogScreen()),
    );
  }

  Future<void> _openFulfillment(PharmacyPrescriptionQueueItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PrescriptionFulfillmentScreen(item: item)),
    );
    refreshQueueData();
  }

  String _greeting() {
    final int hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<_HomeQueueData>(
        future: _queueFuture,
        builder: (context, snapshot) {
          final bool isDark = MHelperFunctions.isDarkMode(context);
          final pendingItems = snapshot.data?.pending ??
              <PharmacyPrescriptionQueueItem>[];
          final dispensedItems = snapshot.data?.dispensed ??
              <PharmacyPrescriptionQueueItem>[];
          final lowStockItems = snapshot.data?.lowStock ??
              <MedicineInventoryItem>[];
          final visiblePending = pendingItems.where((item) {
            final query = _query.trim().toLowerCase();
            if (query.isEmpty) {
              return true;
            }
            return item.patientName.toLowerCase().contains(query) ||
                item.id.toLowerCase().contains(query);
          }).toList();
          final visibleDispensed = dispensedItems.where((item) {
            final query = _query.trim().toLowerCase();
            if (query.isEmpty) {
              return true;
            }
            return item.patientName.toLowerCase().contains(query) ||
                item.id.toLowerCase().contains(query);
          }).toList();
          return SingleChildScrollView(
            child: Column(
              children: [
                ClipPath(
                  clipper: MCurvedEdges(),
                  child: Container(
                    color: MColors.primaryColor,
                    child: SizedBox(
                      height: 240,
                      child: Stack(
                        children: [
                          const Positioned(
                            top: -150,
                            right: -250,
                            child: _CircleAccent(),
                          ),
                          const Positioned(
                            top: 100,
                            right: -300,
                            child: _CircleAccent(),
                          ),
                          Positioned.fill(
                            child: SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const SizedBox(height: 24),
                                    Text(
                                      _greeting(),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      widget.account.fullName.isEmpty
                                          ? 'Pharmacist'
                                          : widget.account.fullName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    LiquidGlassSearchBar(
                                      hintText:
                                          'Search prescription or patient',
                                      onChanged: (value) =>
                                          setState(() => _query = value),
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (lowStockItems.isNotEmpty) ...[
                        _LowStockAlert(
                          items: lowStockItems,
                          onTap: widget.onOpenInventory,
                        ),
                        const SizedBox(height: 12),
                      ],
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _StatTile(
                                icon: Icons.receipt_outlined,
                                label: 'Inventory Log',
                                value: snapshot.data?.logCount ?? 0,
                                isDark: isDark,
                                onTap: _openInventoryLog,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatTile(
                                icon: Icons.check_circle_outline,
                                label: 'Dispensed Today',
                                value: dispensedItems.length,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _SectionHeader(
                        title: 'Pending Prescriptions',
                        count: visiblePending.length,
                      ),
                      const SizedBox(height: 10),
                      if (!snapshot.hasData)
                        const Center(
                          child: CircularProgressIndicator(
                            color: MColors.primaryColor,
                          ),
                        )
                      else ...[
                        for (final item in visiblePending) ...[
                          _QueueCard(
                            item: item,
                            isDark: isDark,
                            onFulfill: () => _openFulfillment(item),
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (visiblePending.isEmpty)
                          _EmptyState(
                            message: 'No pending prescriptions right now.',
                            icon: Icons.inbox_outlined,
                            isDark: isDark,
                          ),
                      ],
                      const SizedBox(height: 14),
                      _SectionHeader(
                        title: 'Dispensed Log',
                        count: visibleDispensed.length,
                      ),
                      const SizedBox(height: 10),
                      if (!snapshot.hasData)
                        const SizedBox.shrink()
                      else if (visibleDispensed.isEmpty)
                        _EmptyState(
                          message: 'No dispensed prescriptions yet.',
                          icon: Icons.history,
                          isDark: isDark,
                        )
                      else
                        for (final item in visibleDispensed) ...[
                          _QueueCard(
                            item: item,
                            isDark: isDark,
                            showFulfillButton: false,
                            trailingColor: Colors.green,
                          ),
                          const SizedBox(height: 10),
                        ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HomeQueueData {
  const _HomeQueueData({
    required this.pending,
    required this.dispensed,
    required this.lowStock,
    required this.logCount,
  });

  final List<PharmacyPrescriptionQueueItem> pending;
  final List<PharmacyPrescriptionQueueItem> dispensed;
  final List<MedicineInventoryItem> lowStock;
  final int logCount;
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final int value;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MColors.primaryColor.withValues(alpha: isDark ? 0.18 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: MColors.primaryColor, size: 18),
              ),
              const SizedBox(height: 10),
              Text(
                '$value',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (onTap != null) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View log',
                      style: TextStyle(
                        color: MColors.primaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.arrow_forward_rounded, color: MColors.primaryColor, size: 12),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: MColors.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            '$count',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: MColors.primaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
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
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: trailingColor.withValues(alpha: 0.12),
                child: Icon(Icons.medication_outlined, color: trailingColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.patientName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.id} • Dr. ${item.doctorName}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: trailingColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  item.status,
                  style: TextStyle(
                    color: trailingColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          if (showFulfillButton) ...[
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
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: '  ${medicine.dosage} • ${medicine.frequency}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: const Size(0, 34),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                icon: const Icon(Icons.arrow_forward, size: 15),
                label: const Text('Review'),
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle, size: 14, color: trailingColor),
                const SizedBox(width: 6),
                Text(
                  '${item.medicines.length} ${item.medicines.length == 1 ? 'medicine' : 'medicines'} dispensed',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, required this.icon, required this.isDark});

  final String message;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 26, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _LowStockAlert extends StatelessWidget {
  const _LowStockAlert({required this.items, required this.onTap});

  final List<MedicineInventoryItem> items;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String names = items.map((MedicineInventoryItem item) => item.name).join(', ');

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${items.length} ${items.length == 1 ? 'medicine is' : 'medicines are'} running low',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      names,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.red.shade700),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleAccent extends StatelessWidget {
  const _CircleAccent();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(400),
      ),
    );
  }
}
