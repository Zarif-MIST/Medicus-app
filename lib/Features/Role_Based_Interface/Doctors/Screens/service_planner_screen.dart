import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medicus/Features/Appointments/Models/doctor_date_override.dart';
import 'package:medicus/Features/Appointments/Services/doctor_date_override_repository.dart';
import 'package:medicus/Features/Authentication/Models/auth_account.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';

const List<String> _kMonthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
const List<String> _kWeekdayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

/// Lets a doctor mark exceptions to their normal weekday-recurring schedule
/// on a calendar: confirm a date as open, or block it off entirely (leave,
/// holiday). Dates with no override keep working exactly as before — this
/// only adds a layer on top, it never disables the existing recurring
/// availability / auto-generated slot system.
class ServicePlannerScreen extends StatefulWidget {
  const ServicePlannerScreen({super.key, required this.doctor});

  final AuthAccount doctor;

  @override
  State<ServicePlannerScreen> createState() => _ServicePlannerScreenState();
}

class _ServicePlannerScreenState extends State<ServicePlannerScreen> {
  static const DoctorDateOverrideRepository _repository =
      DoctorDateOverrideRepository();

  late DateTime _visibleMonth;
  final DateTime _today = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  bool _loading = true;
  Map<DateTime, DoctorDateStatus> _overridesByDate = {};

  String get _doctorId => widget.doctor.firebaseUid ?? widget.doctor.userId;

  @override
  void initState() {
    super.initState();
    _visibleMonth = DateTime(_today.year, _today.month);
    _load();
  }

  Future<void> _load() async {
    try {
      final List<DoctorDateOverride> overrides = await _repository
          .fetchForDoctor(_doctorId);
      if (!mounted) return;
      setState(() {
        _overridesByDate = {
          for (final o in overrides)
            DateTime(o.date.year, o.date.month, o.date.day): o.status,
        };
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _changeMonth(int delta) {
    setState(
      () => _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month + delta,
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _cycleStatus(DateTime date) async {
    if (date.isBefore(_today)) return;

    final DoctorDateStatus? current = _overridesByDate[date];
    // Unset -> Available -> Blocked -> Unset.
    final DoctorDateStatus? next = switch (current) {
      null => DoctorDateStatus.available,
      DoctorDateStatus.available => DoctorDateStatus.blocked,
      DoctorDateStatus.blocked => null,
    };

    final Map<DateTime, DoctorDateStatus> previous = {..._overridesByDate};
    setState(() {
      if (next == null) {
        _overridesByDate.remove(date);
      } else {
        _overridesByDate[date] = next;
      }
    });

    try {
      if (next == null) {
        await _repository.clear(doctorId: _doctorId, date: date);
      } else {
        await _repository.setStatus(
          doctorId: _doctorId,
          date: date,
          status: next,
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _overridesByDate = previous);
      Get.snackbar(
        'Could not save',
        'Check your connection and try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);
    final DateTime firstOfMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month,
      1,
    );
    final int daysInMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;
    final int leadingBlanks = firstOfMonth.weekday % 7;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF181818)
          : const Color(0xFFF7F5F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Service Planner'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: MColors.primaryColor),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                Text(
                  'Tap a date to confirm it as open or block it off — patients '
                  "already see your usual weekly schedule; dates you don't "
                  'touch here are unaffected.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => _changeMonth(-1),
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Text(
                      '${_kMonthNames[_visibleMonth.month - 1]} ${_visibleMonth.year}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _changeMonth(1),
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: _kWeekdayLabels
                      .map(
                        (d) => Expanded(
                          child: Center(
                            child: Text(
                              d,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 4),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: leadingBlanks + daysInMonth,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                  ),
                  itemBuilder: (context, index) {
                    if (index < leadingBlanks) return const SizedBox.shrink();

                    final int day = index - leadingBlanks + 1;
                    final DateTime date = DateTime(
                      _visibleMonth.year,
                      _visibleMonth.month,
                      day,
                    );
                    final bool isPast = date.isBefore(_today);
                    final bool isToday = _isSameDay(date, _today);
                    final DoctorDateStatus? status = _overridesByDate[date];

                    final Color? fill = switch (status) {
                      DoctorDateStatus.available => Colors.green,
                      DoctorDateStatus.blocked => Colors.redAccent,
                      null =>
                        isToday
                            ? MColors.primaryColor.withValues(alpha: 0.1)
                            : null,
                    };

                    return GestureDetector(
                      onTap: isPast ? null : () => _cycleStatus(date),
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: fill,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: status != null
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isPast
                                ? Colors.grey.withValues(alpha: 0.5)
                                : status != null
                                ? Colors.white
                                : (isDark ? Colors.white : Colors.black87),
                            decoration: status == DoctorDateStatus.blocked
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 16,
                  runSpacing: 10,
                  children: const [
                    _LegendDot(color: Colors.green, label: 'Available'),
                    _LegendDot(color: Colors.redAccent, label: 'Blocked'),
                    _LegendDot(
                      color: Colors.transparent,
                      label: 'Default schedule',
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: color == Colors.transparent
                ? Border.all(color: Colors.grey.shade400)
                : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
      ],
    );
  }
}
