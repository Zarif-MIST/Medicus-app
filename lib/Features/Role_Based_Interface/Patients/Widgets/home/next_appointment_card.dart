import 'package:flutter/material.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/doctors/booked_appointment.dart';

const List<String> _kWeekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const List<String> _kMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// A preview of the soonest upcoming appointment. Tapping it opens the
/// appointment calendar — where every marked date can be tapped in turn to
/// see that day's booking — so this card is the entry point into "watch my
/// upcoming appointments" rather than just a bare day-count.
class NextAppointmentCard extends StatelessWidget {
  const NextAppointmentCard({super.key, required this.appointment, required this.onTap});

  final BookedAppointment appointment;
  final VoidCallback onTap;

  String get _formattedDate {
    final DateTime date = appointment.date;
    final int daysFromNow = appointment.daysFromNow;
    if (daysFromNow == 0) return 'Today';
    if (daysFromNow == 1) return 'Tomorrow';
    return '${_kWeekdays[date.weekday - 1]}, ${date.day} ${_kMonths[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: MColors.primaryColor.withValues(alpha: isDark ? 0.18 : 0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.event_available_rounded, color: MColors.primaryColor, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      appointment.doctorName,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${appointment.specialty} · ${appointment.hospital}',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formattedDate,
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, color: MColors.primaryColor),
                  ),
                  Text(appointment.time, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
