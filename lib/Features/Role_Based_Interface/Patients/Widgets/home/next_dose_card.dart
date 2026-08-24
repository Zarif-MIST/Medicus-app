import 'package:flutter/material.dart';
import 'package:medicus/Features/Prescriptions/Models/dose_log_entry.dart';
import 'package:medicus/Features/Prescriptions/Models/prescription_record.dart';
import 'package:medicus/Features/Prescriptions/Models/scheduled_dose.dart';
import 'package:medicus/Features/Prescriptions/Services/dose_log_repository.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Screens/records/dose_schedule_screen.dart';
import 'package:medicus/Utilities/colors.dart';

/// The patient's real next-due medicine — computed from active
/// prescriptions' dose times, not a hardcoded string. "Mark as taken" and
/// "Snooze" write to Firestore (see [DoseLogRepository]) so they persist
/// across restarts, and a tap opens the full adherence/today's-doses view.
class NextDoseCard extends StatefulWidget {
  const NextDoseCard({super.key, required this.patientId, required this.activePrescriptions});

  final String patientId;
  final List<PrescriptionRecord> activePrescriptions;

  @override
  State<NextDoseCard> createState() => _NextDoseCardState();
}

class _NextDoseCardState extends State<NextDoseCard> {
  static const DoseLogRepository _repository = DoseLogRepository();

  List<DoseLogEntry> _logs = [];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant NextDoseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activePrescriptions != widget.activePrescriptions) {
      _load();
    }
  }

  Future<void> _load() async {
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

  List<ScheduledDose> get _todaysDoses {
    final DateTime today = DateTime.now();
    final DateTime dateOnly = DateTime(today.year, today.month, today.day);
    return expandDoseSchedule(
      prescriptions: widget.activePrescriptions,
      rangeStart: dateOnly,
      rangeEnd: dateOnly,
    );
  }

  ScheduledDose? get _nextDose {
    for (final ScheduledDose dose in _todaysDoses) {
      final DoseLogEntry? log = _logFor(dose);
      if (log == null || !log.isTaken) return dose;
    }
    return null;
  }

  bool _isOverlapping(ScheduledDose dose) => overlappingDoseKeys(_todaysDoses).contains(dose.overlapKey);

  /// Fraction of doses already due (scheduled time has passed) in the last
  /// 7 days that were taken. Days with nothing scheduled don't count against
  /// this — there was nothing to adhere to.
  double get _weekAdherence {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final List<ScheduledDose> doses = expandDoseSchedule(
      prescriptions: widget.activePrescriptions,
      rangeStart: today.subtract(const Duration(days: 6)),
      rangeEnd: today,
    ).where((d) => !d.scheduledAt.isAfter(now)).toList();

    if (doses.isEmpty) return 1;
    final int taken = doses.where((d) => _logFor(d)?.isTaken ?? false).length;
    return taken / doses.length;
  }

  Future<void> _markTaken(ScheduledDose dose) async {
    setState(() => _busy = true);
    try {
      await _repository.markTaken(patientId: widget.patientId, dose: dose);
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _snooze(ScheduledDose dose) async {
    setState(() => _busy = true);
    try {
      await _repository.markSnoozed(patientId: widget.patientId, dose: dose);
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openSchedule() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DoseScheduleScreen(
          patientId: widget.patientId,
          activePrescriptions: widget.activePrescriptions,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _Shell(
        child: const SizedBox(
          height: 90,
          child: Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      );
    }

    final ScheduledDose? dose = _nextDose;
    final double adherence = _weekAdherence;

    if (dose == null) {
      final bool nothingScheduled = _todaysDoses.isEmpty;
      return _Shell(
        onTap: _openSchedule,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), shape: BoxShape.circle),
              child: Icon(
                nothingScheduled ? Icons.medication_outlined : Icons.check_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nothingScheduled ? 'No doses scheduled for today' : 'All doses taken for today',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${(adherence * 100).round()}% adherence this week — tap to see details',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final DoseLogEntry? log = _logFor(dose);
    final bool isSnoozed = log?.isActivelySnoozed ?? false;
    final int snoozeMinutesLeft = isSnoozed ? log!.snoozeUntil!.difference(DateTime.now()).inMinutes.clamp(0, 999) : 0;

    return _Shell(
      onTap: _openSchedule,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'NEXT DOSE',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                ),
              ),
              if (isSnoozed) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Snoozed · ${snoozeMinutesLeft}m',
                    style: const TextStyle(color: MColors.primaryColor, fontSize: 10, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                TimeOfDay.fromDateTime(dose.scheduledAt).format(context),
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dose.medicineName,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (dose.doctorName.isNotEmpty)
                      Text(
                        'Prescribed by ${dose.doctorName}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (dose.dosage.isNotEmpty || dose.instructions.isNotEmpty)
                      Text(
                        [dose.dosage, dose.instructions].where((s) => s.isNotEmpty).join(' · '),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (_isOverlapping(dose))
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '⚠ Also prescribed elsewhere',
                          style: TextStyle(color: Colors.orange.shade100, fontSize: 11, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : () => _markTaken(dose),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: MColors.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Mark as taken', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 38,
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _snooze(dose),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.snooze_outlined, size: 16),
                  label: const Text('Snooze 30m', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.18)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'ADHERENCE · 7 DAYS',
                style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.4),
              ),
              const Spacer(),
              Text(
                '${(adherence * 100).round()}%',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: adherence,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(26),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF92140C), Color(0xFF5D0B07)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: MColors.primaryColor.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
