import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:medicus/Features/Authentication/Models/auth_account.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';
import 'package:medicus/Utilities/sizes.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Services/appointment_service.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/doctors/doctor_result_card.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/doctors/booked_appointment.dart';

const List<String> _weekdays = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];
const List<String> _months = [
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

String _formatDate(DateTime date) {
  return '${_weekdays[date.weekday - 1]}, ${date.day} ${_months[date.month - 1]}';
}

class AppointmentConfirmationScreen extends StatefulWidget {
  const AppointmentConfirmationScreen({
    super.key,
    required this.account,
    required this.doctor,
    required this.date,
    required this.time,
    required this.onConfirmed,
  });

  final AuthAccount account;
  final DoctorSummary doctor;
  final DateTime date;
  final String time;
  final ValueChanged<BookedAppointment> onConfirmed;

  @override
  State<AppointmentConfirmationScreen> createState() =>
      _AppointmentConfirmationScreenState();
}

class _AppointmentConfirmationScreenState
    extends State<AppointmentConfirmationScreen> {
  bool _isBooking = false;

  DoctorSummary get doctor => widget.doctor;
  DateTime get date => widget.date;
  String get time => widget.time;

  Future<void> _confirm(BuildContext context) async {
    setState(() => _isBooking = true);

    final BookedAppointment appointment;
    try {
      appointment = await AppointmentService.instance.bookAppointment(
        patient: widget.account,
        doctor: widget.doctor,
        date: widget.date,
        time: widget.time,
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      setState(() => _isBooking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not book appointment: $error')),
      );
      return;
    }

    if (!context.mounted) {
      return;
    }

    setState(() => _isBooking = false);
    widget.onConfirmed(appointment);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 56),
            const SizedBox(height: 16),
            Text(
              'Appointment Booked',
              style: Theme.of(dialogContext).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${doctor.name} • ${_formatDate(date)}, $time',
              style: Theme.of(
                dialogContext,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text(
              'Done',
              style: TextStyle(
                color: MColors.primaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);
    final double pad = Sizes.responsivePadding(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF181818) : Colors.white,
      appBar: AppBar(title: const Text('Confirm Booking')),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(pad, pad * 0.6, pad, pad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Appointment Summary', style: theme.textTheme.titleMedium),
              const SizedBox(height: 14),
              LiquidGlassLayer(
                settings: LiquidGlassSettings(
                  thickness: 16,
                  blur: 10,
                  glassColor: isDark
                      ? const Color(0x22FFFFFF)
                      : const Color(0x92FFFFFF),
                  lightIntensity: 1.05,
                  saturation: 1.12,
                  refractiveIndex: 1.25,
                ),
                child: LiquidGlass(
                  shape: LiquidRoundedSuperellipse(borderRadius: 16),
                  child: Material(
                    color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _SummaryRow(
                            icon: Icons.person_outline,
                            label: 'Doctor',
                            value: doctor.name,
                          ),
                          _SummaryRow(
                            icon: Icons.medical_services_outlined,
                            label: 'Specialty',
                            value: doctor.specialty,
                          ),
                          _SummaryRow(
                            icon: Icons.local_hospital_outlined,
                            label: 'Hospital',
                            value: doctor.hospital,
                          ),
                          _SummaryRow(
                            icon: Icons.event_outlined,
                            label: 'Date',
                            value: _formatDate(date),
                          ),
                          _SummaryRow(
                            icon: Icons.access_time,
                            label: 'Time',
                            value: time,
                          ),
                          _SummaryRow(
                            icon: Icons.payments_outlined,
                            label: 'Fee',
                            value: '৳${doctor.fee}',
                            showDivider: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isBooking ? null : () => _confirm(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MColors.primaryColor,
                    disabledBackgroundColor: MColors.primaryColor.withValues(alpha: 0.6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isBooking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Confirm Booking',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 20, color: MColors.primaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}
