import 'package:flutter/material.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';

/// A single active prescription's course progress — how many days into
/// the prescribed course the patient currently is.
class PrescriptionTimelineEntry {
  const PrescriptionTimelineEntry({
    required this.medicineName,
    required this.dosage,
    required this.dayCurrent,
    required this.dayTotal,
  });

  final String medicineName;
  final String dosage;
  final int dayCurrent;
  final int dayTotal;

  bool get isCompleted => dayCurrent >= dayTotal;
  double get progress => dayTotal == 0 ? 0 : (dayCurrent / dayTotal).clamp(0, 1);
}

class PrescriptionTimeline extends StatelessWidget {
  const PrescriptionTimeline({super.key, required this.entries});

  final List<PrescriptionTimelineEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < entries.length; i++) ...[
          if (i != 0) const SizedBox(height: 12),
          _PrescriptionTimelineRow(entry: entries[i]),
        ],
      ],
    );
  }
}

class _PrescriptionTimelineRow extends StatelessWidget {
  const _PrescriptionTimelineRow({required this.entry});

  final PrescriptionTimelineEntry entry;

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);
    final theme = Theme.of(context);
    final Color statusColor = entry.isCompleted ? Colors.green : MColors.primaryColor;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
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
              Expanded(child: Text(entry.medicineName, style: theme.textTheme.titleSmall)),
              Text(
                entry.isCompleted ? 'Completed' : 'Day ${entry.dayCurrent}/${entry.dayTotal}',
                style: theme.textTheme.bodySmall?.copyWith(color: statusColor, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(entry.dosage, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: entry.progress,
              minHeight: 6,
              backgroundColor: isDark ? Colors.white12 : Colors.black12,
              valueColor: AlwaysStoppedAnimation(statusColor),
            ),
          ),
        ],
      ),
    );
  }
}
