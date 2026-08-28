import 'package:flutter/material.dart';
import 'package:medicus/Features/Role_Based_Interface/Lab_Specialist/Models/lab_order_model.dart';
import 'package:medicus/Features/Role_Based_Interface/Lab_Specialist/Services/lab_service.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';

class LabResultsScreen extends StatefulWidget {
  const LabResultsScreen({super.key});

  @override
  State<LabResultsScreen> createState() => _LabResultsScreenState();
}

class _LabResultsScreenState extends State<LabResultsScreen> {
  late Future<List<LabOrderModel>> _resultsFuture;

  @override
  void initState() {
    super.initState();
    _resultsFuture = _load();
  }

  Future<List<LabOrderModel>> _load() async {
    final List<LabOrderModel> all = await LabService.instance.getAllOrders();
    return all.where((order) => order.status == 'Completed').toList();
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
        title: const Text('Lab Results'),
      ),
      body: FutureBuilder<List<LabOrderModel>>(
        future: _resultsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: MColors.primaryColor),
            );
          }

          final List<LabOrderModel> results = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            children: [
              _ResultsHeader(totalReports: results.length, isDark: isDark),
              const SizedBox(height: 16),
              if (results.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: Text(
                      'No completed lab reports yet.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                  ),
                )
              else
                for (final result in results) ...[
                  _PatientResultTile(result: result, isDark: isDark),
                  const SizedBox(height: 12),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({required this.totalReports, required this.isDark});

  final int totalReports;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: MColors.primaryColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: MColors.primaryColor.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.biotech_outlined, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Patient Lab Findings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalReports reports completed',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
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

class _PatientResultTile extends StatelessWidget {
  const _PatientResultTile({required this.result, required this.isDark});

  final LabOrderModel result;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final Color surfaceColor = isDark ? const Color(0xFF1F1F1F) : Colors.white;
    final Color mutedColor = isDark ? Colors.white60 : Colors.black54;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: MColors.primaryColor,
          collapsedIconColor: MColors.primaryColor,
          leading: CircleAvatar(
            backgroundColor: MColors.primaryColor.withValues(alpha: 0.14),
            child: const Icon(
              Icons.person_search_outlined,
              color: MColors.primaryColor,
            ),
          ),
          title: Text(
            result.patientName,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              result.orderType,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: mutedColor),
            ),
          ),
          children: [
            _MetaLine(
              label: 'Patient ID',
              value: result.patientId,
              mutedColor: mutedColor,
            ),
            _MetaLine(
              label: 'Requested By',
              value: result.requestedBy,
              mutedColor: mutedColor,
            ),
            if (result.completedAt != null)
              _MetaLine(
                label: 'Completed',
                value: _formatDateTime(result.completedAt!),
                mutedColor: mutedColor,
              ),
            if (result.resultFileName != null)
              _MetaLine(
                label: 'Attachment',
                value: result.resultFileName!,
                mutedColor: mutedColor,
              ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : const Color(0xFFF8F5F3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                (result.resultNote == null || result.resultNote!.isEmpty)
                    ? 'No result note was added for this order.'
                    : result.resultNote!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      (result.resultNote == null || result.resultNote!.isEmpty)
                      ? Colors.grey
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.label,
    required this.value,
    required this.mutedColor,
  });

  final String label;
  final String value;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: mutedColor),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
