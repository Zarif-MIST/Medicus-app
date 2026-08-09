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
    required this.prescribedOn,
  });

  final String medicineName;
  final String dosage;
  final int dayCurrent;
  final int dayTotal;
  final DateTime prescribedOn;

  bool get isCompleted => dayCurrent >= dayTotal;
  double get progress => dayTotal == 0 ? 0 : (dayCurrent / dayTotal).clamp(0, 1);
}

/// Renders [entries] as a connected vertical timeline — a dot-and-line
/// rail on the left with each prescription's progress card on the right.
class PrescriptionTimeline extends StatelessWidget {
  const PrescriptionTimeline({super.key, required this.entries});

  final List<PrescriptionTimelineEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < entries.length; i++)
          _PrescriptionTimelineRow(entry: entries[i], isLast: i == entries.length - 1),
      ],
    );
  }
}

class _PrescriptionTimelineRow extends StatelessWidget {
  const _PrescriptionTimelineRow({required this.entry, required this.isLast});

  final PrescriptionTimelineEntry entry;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);
    final theme = Theme.of(context);
    final Color statusColor = entry.isCompleted ? Colors.green : MColors.primaryColor;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: statusColor.withValues(alpha: 0.25), width: 4),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isDark ? Colors.white24 : Colors.black12,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            entry.isCompleted ? 'Completed' : 'Day ${entry.dayCurrent}/${entry.dayTotal}',
                            style: theme.textTheme.bodySmall?.copyWith(color: statusColor, fontWeight: FontWeight.w700),
                          ),
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}
