import 'package:flutter/material.dart';
import 'package:medicus/Features/Prescriptions/Models/dose_log_entry.dart';
import 'package:medicus/Features/Prescriptions/Models/prescription_record.dart';
import 'package:medicus/Features/Prescriptions/Models/scheduled_dose.dart';
import 'package:medicus/Features/Prescriptions/Services/dose_log_repository.dart';
import 'package:medicus/Features/Role_Based_Interface/Lab_Specialist/Models/lab_order_model.dart';
import 'package:medicus/Features/Role_Based_Interface/Lab_Specialist/Services/lab_service.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/doctors/booked_appointment.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';

/// A snapshot of things the patient probably wants to know right now —
/// derived live from data already in Firestore (next appointment, next
/// unt-aken dose, completed lab results) rather than a stored/read
/// notification log. Nothing here needs to be dismissed or persisted;
/// it just reflects current state each time it's opened.
class NotificationsSheet extends StatefulWidget {
  const NotificationsSheet({
    super.key,
    required this.patientId,
    required this.nextAppointment,
    required this.activePrescriptions,
  });

  final String patientId;
  final BookedAppointment? nextAppointment;
  final List<PrescriptionRecord> activePrescriptions;

  @override
  State<NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<NotificationsSheet> {
  static const DoseLogRepository _doseLogRepository = DoseLogRepository();

  late final Future<List<DoseLogEntry>> _doseLogsFuture = _doseLogRepository.fetchForPatient(widget.patientId);
  late final Future<List<LabOrderModel>> _labOrdersFuture =
      LabService.instance.getAllOrdersForPatient(widget.patientId);

  ScheduledDose? _nextDose(List<DoseLogEntry> logs) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final List<ScheduledDose> todaysDoses = expandDoseSchedule(
      prescriptions: widget.activePrescriptions,
      rangeStart: today,
      rangeEnd: today,
    )..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    for (final ScheduledDose dose in todaysDoses) {
      DoseLogEntry? log;
      for (final DoseLogEntry candidate in logs) {
        if (candidate.id == dose.logId) {
          log = candidate;
          break;
        }
      }
      if (log == null || !log.isTaken) {
        return dose;
      }
    }
    return null;
  }

  String _formatDate(DateTime date) {
    const List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Notifications', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              if (widget.nextAppointment != null)
                _NotificationTile(
                  icon: Icons.event_available_rounded,
                  title: 'Upcoming appointment',
                  subtitle:
                      '${MHelperFunctions.doctorNameWithTitle(widget.nextAppointment!.doctorName)} · ${_formatDate(widget.nextAppointment!.date)} · ${widget.nextAppointment!.time}',
                  isDark: isDark,
                ),
              FutureBuilder<List<DoseLogEntry>>(
                future: _doseLogsFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  final ScheduledDose? dose = _nextDose(snapshot.data!);
                  if (dose == null) return const SizedBox.shrink();
                  return _NotificationTile(
                    icon: Icons.medication_outlined,
                    title: 'Medicine reminder',
                    subtitle: '${dose.medicineName} due at ${TimeOfDay.fromDateTime(dose.scheduledAt).format(context)}',
                    isDark: isDark,
                  );
                },
              ),
              FutureBuilder<List<LabOrderModel>>(
                future: _labOrdersFuture,
                builder: (context, snapshot) {
                  final List<LabOrderModel> completed =
                      (snapshot.data ?? const []).where((o) => o.status == 'Completed').toList();
                  if (completed.isEmpty) return const SizedBox.shrink();
                  return Column(
                    children: [
                      for (final LabOrderModel order in completed)
                        _NotificationTile(
                          icon: Icons.science_outlined,
                          title: 'Lab result ready',
                          subtitle: order.orderType,
                          isDark: isDark,
                        ),
                    ],
                  );
                },
              ),
              _EmptyStateIfNoneOf(
                nextAppointment: widget.nextAppointment,
                doseLogsFuture: _doseLogsFuture,
                labOrdersFuture: _labOrdersFuture,
                nextDose: _nextDose,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyStateIfNoneOf extends StatelessWidget {
  const _EmptyStateIfNoneOf({
    required this.nextAppointment,
    required this.doseLogsFuture,
    required this.labOrdersFuture,
    required this.nextDose,
    required this.isDark,
  });

  final BookedAppointment? nextAppointment;
  final Future<List<DoseLogEntry>> doseLogsFuture;
  final Future<List<LabOrderModel>> labOrdersFuture;
  final ScheduledDose? Function(List<DoseLogEntry>) nextDose;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Object>>(
      future: Future.wait([doseLogsFuture, labOrdersFuture]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final List<DoseLogEntry> logs = snapshot.data![0] as List<DoseLogEntry>;
        final List<LabOrderModel> orders = snapshot.data![1] as List<LabOrderModel>;
        final bool hasDose = nextDose(logs) != null;
        final bool hasLabResult = orders.any((o) => o.status == 'Completed');
        if (nextAppointment != null || hasDose || hasLabResult) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Text(
              'Nothing new right now.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ),
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : const Color(0xFFF8F5F3),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: MColors.primaryColor.withValues(alpha: isDark ? 0.18 : 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: MColors.primaryColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
