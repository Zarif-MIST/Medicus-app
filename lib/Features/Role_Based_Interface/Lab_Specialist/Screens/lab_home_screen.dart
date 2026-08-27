import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medicus/Features/Authentication/Models/auth_account.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Widgets/LiquidSearchBar.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Widgets/customShapes.dart';
import 'package:medicus/Features/Role_Based_Interface/Lab_Specialist/Models/lab_order_model.dart';
import 'package:medicus/Features/Role_Based_Interface/Lab_Specialist/Screens/lab_order_log_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Lab_Specialist/Screens/lab_result_upload_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Lab_Specialist/Screens/lab_results_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Lab_Specialist/Services/lab_service.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';

class LabHomeScreen extends StatefulWidget {
  const LabHomeScreen({super.key, required this.account});

  final AuthAccount account;

  @override
  State<LabHomeScreen> createState() => LabHomeScreenState();
}

enum _HomeSection { pending, completed }

class LabHomeScreenState extends State<LabHomeScreen> {
  late Future<List<LabOrderModel>> _ordersFuture;
  String _query = '';
  _HomeSection _selectedSection = _HomeSection.pending;

  @override
  void initState() {
    super.initState();
    _ordersFuture = LabService.instance.getAllOrders();
  }

  void refreshOrdersData() {
    setState(() {
      _ordersFuture = LabService.instance.getAllOrders();
    });
  }

  Future<void> _openOrderLog() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LabOrderLogScreen()));
  }

  Future<void> _openResults() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LabResultsScreen()));
  }

  Future<void> _openUpload(LabOrderModel order) async {
    await Get.to(
      () => LabResultUploadScreen(order: order),
      transition: Transition.fadeIn,
    );
    refreshOrdersData();
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
      body: FutureBuilder<List<LabOrderModel>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          final bool isDark = MHelperFunctions.isDarkMode(context);
          final List<LabOrderModel> orders = snapshot.data ?? <LabOrderModel>[];
          final List<LabOrderModel> pendingOrders = orders
              .where((order) => order.status != 'Completed')
              .toList();
          final List<LabOrderModel> completedOrders = orders
              .where((order) => order.status == 'Completed')
              .toList();

          List<LabOrderModel> filter(List<LabOrderModel> list) {
            final String query = _query.trim().toLowerCase();
            if (query.isEmpty) {
              return list;
            }
            return list
                .where(
                  (order) =>
                      order.patientName.toLowerCase().contains(query) ||
                      order.patientId.toLowerCase().contains(query),
                )
                .toList();
          }

          final List<LabOrderModel> visiblePending = filter(pendingOrders);
          final List<LabOrderModel> visibleCompleted = filter(completedOrders);

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
                                          ? 'Lab Specialist'
                                          : widget.account.fullName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    LiquidGlassSearchBar(
                                      hintText: 'Search order or patient',
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
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _StatTile(
                                icon: Icons.receipt_outlined,
                                label: 'Order Log',
                                value: orders.length,
                                isDark: isDark,
                                onTap: _openOrderLog,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatTile(
                                icon: Icons.check_circle_outline,
                                label: 'Results',
                                value: completedOrders.length,
                                isDark: isDark,
                                onTap: _openResults,
                                actionLabel: 'View results',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _SectionToggle(
                        selected: _selectedSection,
                        pendingCount: visiblePending.length,
                        completedCount: visibleCompleted.length,
                        onChanged: (section) =>
                            setState(() => _selectedSection = section),
                      ),
                      const SizedBox(height: 14),
                      if (!snapshot.hasData)
                        const Center(
                          child: CircularProgressIndicator(
                            color: MColors.primaryColor,
                          ),
                        )
                      else if (_selectedSection == _HomeSection.pending) ...[
                        for (final order in visiblePending) ...[
                          _QueueCard(
                            order: order,
                            isDark: isDark,
                            onAttachResult: () => _openUpload(order),
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (visiblePending.isEmpty)
                          _EmptyState(
                            message: 'No pending lab orders right now.',
                            icon: Icons.inbox_outlined,
                            isDark: isDark,
                          ),
                      ] else ...[
                        if (visibleCompleted.isEmpty)
                          _EmptyState(
                            message: 'No completed lab orders yet.',
                            icon: Icons.history,
                            isDark: isDark,
                          )
                        else
                          for (final order in visibleCompleted) ...[
                            _QueueCard(
                              order: order,
                              isDark: isDark,
                              trailingColor: Colors.green,
                            ),
                            const SizedBox(height: 10),
                          ],
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

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.onTap,
    this.actionLabel = 'View log',
  });

  final IconData icon;
  final String label;
  final int value;
  final bool isDark;
  final VoidCallback? onTap;
  final String actionLabel;

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
                  color: MColors.primaryColor.withValues(
                    alpha: isDark ? 0.18 : 0.1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: MColors.primaryColor, size: 18),
              ),
              const SizedBox(height: 10),
              Text(
                '$value',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (onTap != null) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel,
                      style: TextStyle(
                        color: MColors.primaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: MColors.primaryColor,
                      size: 12,
                    ),
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

class _SectionToggle extends StatelessWidget {
  const _SectionToggle({
    required this.selected,
    required this.pendingCount,
    required this.completedCount,
    required this.onChanged,
  });

  final _HomeSection selected;
  final int pendingCount;
  final int completedCount;
  final ValueChanged<_HomeSection> onChanged;

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _SectionToggleSegment(
              label: 'Pending',
              count: pendingCount,
              isSelected: selected == _HomeSection.pending,
              onTap: () => onChanged(_HomeSection.pending),
            ),
          ),
          Expanded(
            child: _SectionToggleSegment(
              label: 'Completed',
              count: completedCount,
              isSelected: selected == _HomeSection.completed,
              onTap: () => onChanged(_HomeSection.completed),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionToggleSegment extends StatelessWidget {
  const _SectionToggleSegment({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? MColors.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.22)
                    : Colors.grey.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueCard extends StatelessWidget {
  const _QueueCard({
    required this.order,
    required this.isDark,
    this.onAttachResult,
    this.trailingColor = MColors.primaryColor,
  });

  final LabOrderModel order;
  final bool isDark;
  final VoidCallback? onAttachResult;
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
                child: Icon(
                  Icons.science_outlined,
                  color: trailingColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.patientName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Patient ID: ${order.patientId} • ${order.requestedBy}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey),
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
                  order.status,
                  style: TextStyle(
                    color: trailingColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 15,
                color: MColors.primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.orderType,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (onAttachResult != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: onAttachResult,
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
                icon: const Icon(Icons.upload_file, size: 15),
                label: const Text('Attach Result'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.message,
    required this.icon,
    required this.isDark,
  });

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
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
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
