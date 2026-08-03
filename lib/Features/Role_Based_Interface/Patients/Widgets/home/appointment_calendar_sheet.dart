import 'package:flutter/material.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/doctors/booked_appointment.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';

const List<String> _kMonthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
const List<String> _kWeekdayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

/// A draggable bottom sheet showing a month calendar with the patient's
/// appointment dates marked. Tapping a marked date reveals that day's
/// appointment details below the grid.
class AppointmentCalendarSheet extends StatefulWidget {
  const AppointmentCalendarSheet({super.key, required this.appointments});

  final List<BookedAppointment> appointments;

  @override
  State<AppointmentCalendarSheet> createState() => _AppointmentCalendarSheetState();
}

class _AppointmentCalendarSheetState extends State<AppointmentCalendarSheet> {
  late DateTime _visibleMonth;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    final DateTime today = DateTime.now();
    _visibleMonth = DateTime(today.year, today.month);

    if (widget.appointments.isNotEmpty) {
      final List<BookedAppointment> sorted = [...widget.appointments]
        ..sort((a, b) => a.date.compareTo(b.date));
      final DateTime firstAppointment = sorted.first.date;
      _selectedDay = DateTime(firstAppointment.year, firstAppointment.month, firstAppointment.day);
      _visibleMonth = DateTime(_selectedDay!.year, _selectedDay!.month);
    }
  }

  Map<DateTime, List<BookedAppointment>> get _appointmentsByDay {
    final Map<DateTime, List<BookedAppointment>> map = {};
    for (final BookedAppointment appointment in widget.appointments) {
      final DateTime key = DateTime(appointment.date.year, appointment.date.month, appointment.date.day);
      map.putIfAbsent(key, () => []).add(appointment);
    }
    return map;
  }

  void _changeMonth(int delta) {
    setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta));
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);
    final Map<DateTime, List<BookedAppointment>> byDay = _appointmentsByDay;
    final List<BookedAppointment> selected = _selectedDay == null ? const [] : (byDay[_selectedDay] ?? const []);

    final DateTime firstOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final int daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final int leadingBlanks = firstOfMonth.weekday % 7; // Sunday-first grid

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF181818) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text('Appointment Calendar', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Marked dates have a scheduled appointment.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
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
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
                itemBuilder: (context, index) {
                  if (index < leadingBlanks) return const SizedBox.shrink();

                  final int day = index - leadingBlanks + 1;
                  final DateTime date = DateTime(_visibleMonth.year, _visibleMonth.month, day);
                  final bool hasAppointment = byDay.containsKey(date);
                  final bool isSelected = _selectedDay != null && _isSameDay(_selectedDay!, date);
                  final bool isToday = _isSameDay(date, DateTime.now());

                  return GestureDetector(
                    onTap: hasAppointment ? () => setState(() => _selectedDay = date) : null,
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? MColors.primaryColor
                            : (isToday ? MColors.primaryColor.withValues(alpha: 0.1) : null),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$day',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: hasAppointment ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                          if (hasAppointment)
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white : MColors.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              if (selected.isNotEmpty) ...[
                Text(
                  'On ${_kMonthNames[_selectedDay!.month - 1].substring(0, 3)} ${_selectedDay!.day}, ${_selectedDay!.year}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 10),
                for (final BookedAppointment appointment in selected) ...[
                  _AppointmentTile(appointment: appointment),
                  const SizedBox(height: 10),
                ],
              ] else if (widget.appointments.isEmpty)
                Text(
                  'No appointments scheduled yet.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  const _AppointmentTile({required this.appointment});

  final BookedAppointment appointment;

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);

    return Container(
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: MColors.primaryColor.withValues(alpha: isDark ? 0.18 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.event_outlined, color: MColors.primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appointment.doctorName, style: Theme.of(context).textTheme.titleSmall),
                Text(
                  '${appointment.specialty} · ${appointment.hospital}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            appointment.time,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
