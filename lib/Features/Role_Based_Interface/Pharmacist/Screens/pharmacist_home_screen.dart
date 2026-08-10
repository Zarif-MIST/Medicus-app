import 'package:flutter/material.dart';
import 'package:medicus/Features/Authentication/Models/auth_account.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Widgets/LiquidSearchBar.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Widgets/customShapes.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/home/stat_card_row.dart';
import 'package:medicus/Features/Role_Based_Interface/Pharmacist/Models/pharmacy_prescription_queue_item.dart';
import 'package:medicus/Features/Role_Based_Interface/Pharmacist/Services/pharmacist_service.dart';
import 'package:medicus/Utilities/colors.dart';

class PharmacistHomeScreen extends StatefulWidget {
  const PharmacistHomeScreen({
    super.key,
    required this.account,
    required this.onOpenQueue,
    required this.onOpenScanner,
  });

  final AuthAccount account;
  final VoidCallback onOpenQueue;
  final VoidCallback onOpenScanner;

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
    final results = await Future.wait<List<PharmacyPrescriptionQueueItem>>([
      PharmacistService.instance.getPendingPrescriptions(),
      PharmacistService.instance.getDispensedPrescriptions(),
    ]);

    return _HomeQueueData(
      pending: results[0],
      dispensed: results[1],
    );
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
          final pendingItems = snapshot.data?.pending ??
              <PharmacyPrescriptionQueueItem>[];
          final dispensedItems = snapshot.data?.dispensed ??
              <PharmacyPrescriptionQueueItem>[];
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
          final allItems = <PharmacyPrescriptionQueueItem>[
            ...pendingItems,
            ...dispensedItems,
          ];

          return SingleChildScrollView(
            child: Column(
              children: [
                ClipPath(
                  clipper: MCurvedEdges(),
                  child: Container(
                    color: MColors.primaryColor,
                    child: SizedBox(
                      height: 420,
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
                                    const SizedBox(height: 50),
                                    Text(
                                      _greeting(),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.account.fullName.isEmpty
                                          ? 'Pharmacist'
                                          : widget.account.fullName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 28),
                                    LiquidGlassSearchBar(
                                      hintText:
                                          'Search prescription or patient',
                                      onChanged: (value) =>
                                          setState(() => _query = value),
                                    ),
                                    const SizedBox(height: 24),
                                    Align(
                                      alignment: Alignment.center,
                                      child: IconButton(
                                        onPressed: widget.onOpenScanner,
                                        icon: const Icon(
                                          Icons.qr_code_scanner,
                                        ),
                                        color: Colors.white,
                                        iconSize: 30,
                                        tooltip: 'Scan QR',
                                      ),
                                    ),
                                    const SizedBox(height: 18),
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
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StatCardRow(
                        onHighlightTap: widget.onOpenQueue,
                        highlightActionLabel: 'View queue',
                        stats: [
                          StatCardData(
                            label: 'Pending Queue',
                            value: pendingItems
                                .where((item) => item.status == 'Pending')
                                .length,
                            icon: Icons.receipt_long_outlined,
                          ),
                          StatCardData(
                            label: 'Dispensed Today',
                            value: dispensedItems.length,
                            icon: Icons.check_circle_outline,
                          ),
                          StatCardData(
                            label: 'Queue Items',
                            value: pendingItems.length,
                            icon: Icons.inventory_2_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Pending Prescriptions',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      if (!snapshot.hasData)
                        const Center(
                          child: CircularProgressIndicator(
                            color: MColors.primaryColor,
                          ),
                        )
                      else
                        for (final item in visiblePending.take(3)) ...[
                          _QueuePreview(item: item),
                          const SizedBox(height: 12),
                        ],
                      const SizedBox(height: 10),
                      Text(
                        'Dispensed Log',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      if (!snapshot.hasData)
                        const SizedBox.shrink()
                      else
                        for (final item in visibleDispensed.take(3)) ...[
                          _QueuePreview(item: item),
                          const SizedBox(height: 12),
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
  const _HomeQueueData({required this.pending, required this.dispensed});

  final List<PharmacyPrescriptionQueueItem> pending;
  final List<PharmacyPrescriptionQueueItem> dispensed;
}

class _QueuePreview extends StatelessWidget {
  const _QueuePreview({required this.item});

  final PharmacyPrescriptionQueueItem item;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool pending = item.status == 'Pending';

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
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: MColors.primaryColor.withValues(alpha: 0.14),
            child: const Icon(
              Icons.medication_outlined,
              color: MColors.primaryColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.patientName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  item.id,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: (pending ? MColors.primaryColor : Colors.green).withValues(
                alpha: 0.12,
              ),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              item.status,
              style: TextStyle(
                color: pending ? MColors.primaryColor : Colors.green,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
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
