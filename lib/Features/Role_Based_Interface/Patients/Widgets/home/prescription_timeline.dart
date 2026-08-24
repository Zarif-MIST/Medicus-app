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
    required this.doctorName,
    required this.prescriptionId,
  });

  final String medicineName;
  final String dosage;
  final int dayCurrent;
  final int dayTotal;
  final DateTime prescribedOn;
  final String doctorName;
  final String prescriptionId;

  bool get isCompleted => dayCurrent >= dayTotal;
  double get progress => dayTotal == 0 ? 0 : (dayCurrent / dayTotal).clamp(0, 1);
}

/// Medicine names shared by more than one currently-active (not yet
/// completed) entry among [entries] — a likely sign of overlapping courses
/// from a follow-up visit or a different doctor, surfaced as a warning
/// rather than silently merged, since the two courses may genuinely be
/// separate and both need to be taken.
Set<String> overlappingMedicineNames(List<PrescriptionTimelineEntry> entries) {
  final Map<String, int> activeCountByName = {};
  for (final PrescriptionTimelineEntry entry in entries) {
    if (entry.isCompleted) continue;
    final String key = entry.medicineName.trim().toLowerCase();
    activeCountByName[key] = (activeCountByName[key] ?? 0) + 1;
  }
  return {
    for (final MapEntry<String, int> entry in activeCountByName.entries)
      if (entry.value > 1) entry.key,
  };
}

/// Renders [entries] as a connected vertical timeline — a dot-and-line
/// rail on the left with each prescription's progress card on the right.
/// Pass [overlapNamesOverride] when [entries] is a truncated slice of a
/// larger list (e.g. the home screen's "top 4" preview) so overlap
/// detection still sees every active prescription, not just the visible
/// ones — otherwise a duplicate sitting just past the cap would go unflagged.
class PrescriptionTimeline extends StatelessWidget {
  const PrescriptionTimeline({super.key, required this.entries, this.overlapNamesOverride});

  final List<PrescriptionTimelineEntry> entries;
  final Set<String>? overlapNamesOverride;

  @override
  Widget build(BuildContext context) {
    final Set<String> overlapNames = overlapNamesOverride ?? overlappingMedicineNames(entries);
    return Column(
      children: [
        for (int i = 0; i < entries.length; i++)
          _PrescriptionTimelineRow(
            entry: entries[i],
            isLast: i == entries.length - 1,
            isOverlapping: overlapNames.contains(entries[i].medicineName.trim().toLowerCase()),
          ),
      ],
    );
  }
}

class _PrescriptionTimelineRow extends StatelessWidget {
  const _PrescriptionTimelineRow({required this.entry, required this.isLast, required this.isOverlapping});

  final PrescriptionTimelineEntry entry;
  final bool isLast;
  final bool isOverlapping;

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
                    if (entry.doctorName.isNotEmpty)
                      Text(
                        'Prescribed by ${entry.doctorName}',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    if (isOverlapping)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '⚠ Also prescribed elsewhere — confirm with your doctor or pharmacist',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange.shade800, fontWeight: FontWeight.w600),
                        ),
                      ),
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
