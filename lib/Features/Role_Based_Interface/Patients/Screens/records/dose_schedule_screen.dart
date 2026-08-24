import 'package:flutter/material.dart';
import 'package:medicus/Features/Prescriptions/Models/dose_log_entry.dart';
import 'package:medicus/Features/Prescriptions/Models/prescription_record.dart';
import 'package:medicus/Features/Prescriptions/Models/scheduled_dose.dart';
import 'package:medicus/Features/Prescriptions/Services/dose_log_repository.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';
import 'package:medicus/Utilities/sizes.dart';

const List<String> _kWeekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
const List<String> _kWeekdayNames = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];

class _DayAdherence {
  const _DayAdherence({required this.day, required this.taken, required this.due});

  final DateTime day;
  final int taken;
  final int due;

  double get ratio => due == 0 ? 1 : taken / due;
  bool get hasShortfall => due > 0 && taken < due;
}

/// The full "today's doses / adherence" view a tap on the compact
/// [NextDoseCard] opens — a 7-day adherence strip with a streak call-out,
/// then every dose due today with its own mark-taken toggle.
class DoseScheduleScreen extends StatefulWidget {
  const DoseScheduleScreen({super.key, required this.patientId, required this.activePrescriptions});

  final String patientId;
  final List<PrescriptionRecord> activePrescriptions;

  @override
  State<DoseScheduleScreen> createState() => _DoseScheduleScreenState();
}

class _DoseScheduleScreenState extends State<DoseScheduleScreen> {
  static const DoseLogRepository _repository = DoseLogRepository();

  List<DoseLogEntry> _logs = [];
  bool _loading = true;

  /// null = viewing every doctor's doses together (the default). Picking a
  /// doctor scopes the 7-day adherence chart, streak, and today's list to
  /// just that doctor's prescriptions — a patient juggling several doctors
  /// can then judge "am I keeping up with Dr. X specifically" separately
  /// from their overall adherence.
  String? _selectedDoctor;

  /// Doctor names across every active prescription, in first-appearance
  /// order (roughly most-recently-prescribed first, since callers already
  /// tend to pass prescriptions newest-first).
  List<String> get _doctorNames {
    final List<String> names = [];
    for (final PrescriptionRecord p in widget.activePrescriptions) {
      if (p.doctorName.isNotEmpty && !names.contains(p.doctorName)) names.add(p.doctorName);
    }
    return names;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final List<DoseLogEntry> logs = await _repository.fetchForPatient(widget.patientId);
      if (!mounted) return;
      setState(() {
        _logs = logs;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  DoseLogEntry? _logFor(ScheduledDose dose) {
    for (final DoseLogEntry log in _logs) {
      if (log.id == dose.logId) return log;
    }
    return null;
  }

  /// [applyFilter] defaults to true so the 7-day chart and "today" list
  /// respect [_selectedDoctor]; pass false when you need the full unfiltered
  /// set regardless of the active filter (overlap detection needs to see
  /// every doctor's doses even while zoomed into one, since a duplicate
  /// with a doctor not currently selected is still worth flagging).
  List<ScheduledDose> _dosesOn(DateTime day, {bool applyFilter = true}) {
    final List<ScheduledDose> doses = expandDoseSchedule(
      prescriptions: widget.activePrescriptions,
      rangeStart: day,
      rangeEnd: day,
    );
    if (!applyFilter || _selectedDoctor == null) return doses;
    return doses.where((d) => d.doctorName == _selectedDoctor).toList();
  }

  List<_DayAdherence> get _last7Days {
    final DateTime today = DateTime.now();
    final DateTime todayDateOnly = DateTime(today.year, today.month, today.day);
    return [
      for (int i = 6; i >= 0; i--)
        () {
          final DateTime day = todayDateOnly.subtract(Duration(days: i));
          final List<ScheduledDose> doses =
              _dosesOn(day).where((d) => !d.scheduledAt.isAfter(DateTime.now())).toList();
          final int taken = doses.where((d) => _logFor(d)?.isTaken ?? false).length;
          return _DayAdherence(day: day, taken: taken, due: doses.length);
        }(),
    ];
  }

  String _streakSentence(List<_DayAdherence> last7) {
    // Exclude today (index 6) — it isn't finished yet, so it shouldn't
    // break or extend a streak either way.
    final List<_DayAdherence> priorDays = last7.sublist(0, 6);

    int streak = 0;
    for (int i = priorDays.length - 1; i >= 0; i--) {
      if (priorDays[i].due == 0 || priorDays[i].ratio >= 1) {
        streak++;
      } else {
        break;
      }
    }

    final Iterable<_DayAdherence> shortfalls = priorDays.where((d) => d.hasShortfall);

    if (streak == 0) {
      if (shortfalls.isEmpty) return 'No doses due yet this week.';
      final _DayAdherence lastShortfall = shortfalls.last;
      return 'Missed a dose on ${_kWeekdayNames[lastShortfall.day.weekday - 1]} — let\'s restart the streak today.';
    }

    if (shortfalls.isEmpty) {
      return '$streak-day streak — perfect week so far.';
    }

    final _DayAdherence lastShortfall = shortfalls.last;
    return '$streak-day streak — one dose missed on ${_kWeekdayNames[lastShortfall.day.weekday - 1]}.';
  }

  Future<void> _toggleTaken(ScheduledDose dose, bool currentlyTaken) async {
    try {
      if (currentlyTaken) {
        await _repository.clearLog(dose.logId);
      } else {
        await _repository.markTaken(patientId: widget.patientId, dose: dose);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't update that dose — try again.")),
        );
      }
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);
    final double pad = Sizes.responsivePadding(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF181818) : Colors.white,
      appBar: AppBar(title: const Text('Dose Schedule')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: MColors.primaryColor))
            : Builder(
                builder: (context) {
                  final List<_DayAdherence> last7 = _last7Days;
                  final int totalTaken = last7.fold(0, (sum, d) => sum + d.taken);
                  final int totalDue = last7.fold(0, (sum, d) => sum + d.due);
                  final double weekRatio = totalDue == 0 ? 1 : totalTaken / totalDue;

                  final DateTime today = DateTime.now();
                  final DateTime todayOnly = DateTime(today.year, today.month, today.day);
                  final List<ScheduledDose> todaysDosesAll = _dosesOn(todayOnly, applyFilter: false);
                  final List<ScheduledDose> todaysDoses = _dosesOn(todayOnly);
                  final int todayTaken = todaysDoses.where((d) => _logFor(d)?.isTaken ?? false).length;
                  final Set<String> overlapKeys = overlappingDoseKeys(todaysDosesAll);
                  final List<String> doctorNames = _doctorNames;

                  return ListView(
                    padding: EdgeInsets.fromLTRB(pad, pad * 0.6, pad, pad * 2),
                    children: [
                      if (doctorNames.length > 1) ...[
                        SizedBox(
                          height: 34,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: doctorNames.length + 1,
                            separatorBuilder: (_, _) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final String? doctor = index == 0 ? null : doctorNames[index - 1];
                              final bool selected = _selectedDoctor == doctor;
                              return ChoiceChip(
                                label: Text(doctor ?? 'All Doctors'),
                                selected: selected,
                                onSelected: (_) => setState(() => _selectedDoctor = doctor),
                                selectedColor: MColors.primaryColor,
                                labelStyle: TextStyle(
                                  color: selected ? Colors.white : null,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                                visualDensity: VisualDensity.compact,
                              );
                            },
                          ),
                        ),
                        SizedBox(height: pad * 0.8),
                      ],
                      Row(
                        children: [
                          Text('Adherence · 7 days', style: theme.textTheme.titleMedium),
                          const Spacer(),
                          Text(
                            '${(weekRatio * 100).round()}%',
                            style: theme.textTheme.titleMedium?.copyWith(color: MColors.primaryColor, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          for (final _DayAdherence day in last7) ...[
                            Expanded(child: _DayCell(day: day, isDark: isDark)),
                            if (day != last7.last) const SizedBox(width: 8),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.local_fire_department_rounded, color: MColors.primaryColor, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _streakSentence(last7),
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: pad * 1.4),
                      Row(
                        children: [
                          Text('Today · $todayTaken/${todaysDoses.length} taken', style: theme.textTheme.titleMedium),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (todaysDoses.isEmpty)
                        Text(
                          _selectedDoctor == null
                              ? 'No doses scheduled for today.'
                              : 'No doses from $_selectedDoctor scheduled for today.',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                        )
                      else
                        for (int i = 0; i < todaysDoses.length; i++) ...[
                          _DoseRow(
                            dose: todaysDoses[i],
                            isTaken: _logFor(todaysDoses[i])?.isTaken ?? false,
                            isDark: isDark,
                            isOverlapping: overlapKeys.contains(todaysDoses[i].overlapKey),
                            onToggle: (currentlyTaken) => _toggleTaken(todaysDoses[i], currentlyTaken),
                          ),
                          if (i != todaysDoses.length - 1) const Divider(height: 20),
                        ],
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.isDark});

  final _DayAdherence day;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = day.due == 0;
    final bool isFull = day.due > 0 && day.taken >= day.due;
    final Color trackColor = isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06);

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              color: trackColor,
              child: isEmpty
                  ? null
                  : Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: day.ratio.clamp(0.08, 1.0),
                        widthFactor: 1,
                        child: Container(
                          color: isFull ? MColors.primaryColor : MColors.primaryColor.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _kWeekdayLetters[day.day.weekday - 1],
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black54),
        ),
      ],
    );
  }
}

class _DoseRow extends StatelessWidget {
  const _DoseRow({
    required this.dose,
    required this.isTaken,
    required this.isDark,
    required this.isOverlapping,
    required this.onToggle,
  });

  final ScheduledDose dose;
  final bool isTaken;
  final bool isDark;
  final bool isOverlapping;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 52,
          child: Text(
            TimeOfDay.fromDateTime(dose.scheduledAt).format(context),
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dose.medicineName, style: theme.textTheme.titleSmall),
              if (dose.doctorName.isNotEmpty)
                Text(
                  'Prescribed by ${dose.doctorName}',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              if (dose.dosage.isNotEmpty || dose.instructions.isNotEmpty)
                Text(
                  [dose.dosage, dose.instructions].where((s) => s.isNotEmpty).join(' · '),
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
            ],
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: isTaken ? MColors.primaryColor : Colors.transparent,
          shape: const CircleBorder(side: BorderSide(color: MColors.primaryColor, width: 1.5)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => onToggle(isTaken),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.check, size: 18, color: isTaken ? Colors.white : MColors.primaryColor),
            ),
          ),
        ),
      ],
    );
  }
}
