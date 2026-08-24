import 'package:flutter/material.dart';
import 'package:medicus/Features/Authentication/Models/auth_account.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';
import 'package:medicus/Utilities/sizes.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/doctors/doctor_result_card.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/doctors/booked_appointment.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Screens/doctors/appointment_confirmation_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Services/appointment_service.dart';

/// Clinic hours every doctor sees patients within — fixed across the app.
const int _clinicStartMinutes = 8 * 60;
const int _clinicEndMinutes = 14 * 60;

/// Builds the day's bookable time labels (e.g. "9:00 AM") by stepping from
/// 8:00 AM to 2:00 PM in increments of the doctor's average consultation
/// time, so a slower doctor gets fewer, longer slots and a faster one gets
/// more, shorter slots — the last slot always finishes by 2:00 PM.
List<String> _generateTimeSlots(int consultationMinutes) {
  final int step = consultationMinutes.clamp(1, 120);
  final List<String> slots = [];
  for (
    int minutes = _clinicStartMinutes;
    minutes + step <= _clinicEndMinutes;
    minutes += step
  ) {
    slots.add(_formatTimeLabel(minutes));
  }
  return slots;
}

String _formatTimeLabel(int minutesFromMidnight) {
  final int hour24 = minutesFromMidnight ~/ 60;
  final int minute = minutesFromMidnight % 60;
  final String period = hour24 >= 12 ? 'PM' : 'AM';
  final int hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  return '$hour12:${minute.toString().padLeft(2, '0')} $period';
}

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({
    super.key,
    required this.account,
    required this.doctor,
    required this.onBooked,
  });

  final AuthAccount account;
  final DoctorSummary doctor;
  final ValueChanged<BookedAppointment> onBooked;

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  late final List<DateTime> _dates = List.generate(
    7,
    (i) => DateTime.now().add(Duration(days: i)),
  );

  late final List<String> _timeSlots = _generateTimeSlots(
    widget.doctor.avgConsultationMinutes,
  );

  int _selectedDateIndex = 0;
  String? _selectedSlot;
  late Future<Set<String>> _bookedTimesFuture;

  @override
  void initState() {
    super.initState();
    _bookedTimesFuture = _loadBookedTimes();
  }

  Future<Set<String>> _loadBookedTimes() {
    return AppointmentService.instance.getBookedTimesForDoctor(
      doctorId: widget.doctor.id,
      date: _dates[_selectedDateIndex],
    );
  }

  void _selectDate(int index) {
    setState(() {
      _selectedDateIndex = index;
      _selectedSlot = null;
      _bookedTimesFuture = _loadBookedTimes();
    });
  }

  void _selectSlot(String slot) {
    setState(() => _selectedSlot = slot);
  }

  void _handleBook() {
    if (_selectedSlot == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AppointmentConfirmationScreen(
          account: widget.account,
          doctor: widget.doctor,
          date: _dates[_selectedDateIndex],
          time: _selectedSlot!,
          onConfirmed: widget.onBooked,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);
    final double pad = Sizes.responsivePadding(context);
    final theme = Theme.of(context);
    final DoctorSummary doctor = widget.doctor;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF181818) : Colors.white,
      appBar: AppBar(title: const Text('Doctor Profile')),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.fromLTRB(pad, pad * 0.6, pad, 100),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: MColors.primaryColor.withValues(alpha: 0.12),
                      child: const Icon(Icons.person, color: MColors.primaryColor, size: 34),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(doctor.name, style: theme.textTheme.titleLarge),
                          const SizedBox(height: 2),
                          Text(
                            '${doctor.specialty} • ${doctor.experienceYears} yrs exp',
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            doctor.hospital,
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.star, size: 15, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                doctor.rating.toStringAsFixed(1),
                                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '৳${doctor.fee} fee',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: MColors.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: pad),
                Text('About', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  '${doctor.name} is a ${doctor.specialty.toLowerCase()} specialist at ${doctor.hospital}, '
                  'with ${doctor.experienceYears} years of experience helping patients with '
                  'consultations, diagnoses, and ongoing treatment plans.',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey, height: 1.4),
                ),
                SizedBox(height: pad),
                Text('Select Date', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _dates.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final DateTime date = _dates[i];
                      final bool selected = i == _selectedDateIndex;
                      return _DateChip(
                        date: date,
                        selected: selected,
                        isDark: isDark,
                        onTap: () => _selectDate(i),
                      );
                    },
                  ),
                ),
                SizedBox(height: pad * 0.8),
                Text('Select Time', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Clinic hours 8:00 AM – 2:00 PM • ~${widget.doctor.avgConsultationMinutes} min per patient',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 12),
                FutureBuilder<Set<String>>(
                  future: _bookedTimesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: MColors.primaryColor,
                          ),
                        ),
                      );
                    }

                    final Set<String> bookedTimes =
                        snapshot.data ?? <String>{};

                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final slot in _timeSlots)
                          _SlotChip(
                            label: slot,
                            selected: slot == _selectedSlot,
                            booked: bookedTimes.contains(slot),
                            isDark: isDark,
                            onTap: bookedTimes.contains(slot)
                                ? null
                                : () => _selectSlot(slot),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
            Positioned(
              left: pad,
              right: pad,
              bottom: 16,
              child: ElevatedButton(
                onPressed: _selectedSlot == null ? null : _handleBook,
                style: ElevatedButton.styleFrom(
                  backgroundColor: MColors.primaryColor,
                  disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Book Appointment',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.date, required this.selected, required this.isDark, required this.onTap});

  final DateTime date;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  static const List<String> _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? MColors.primaryColor : (isDark ? const Color(0xFF1F1F1F) : Colors.white),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 54,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _weekdays[date.weekday - 1],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white70 : Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
    this.booked = false,
  });

  final String label;
  final bool selected;
  final bool isDark;
  final bool booked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color background = booked
        ? (isDark ? const Color(0xFF141414) : Colors.grey.shade200)
        : selected
        ? MColors.primaryColor
        : (isDark ? const Color(0xFF1F1F1F) : Colors.white);
    final Color textColor = booked
        ? Colors.grey
        : selected
        ? Colors.white
        : (isDark ? Colors.white70 : Colors.black87);

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  decoration: booked ? TextDecoration.lineThrough : null,
                ),
              ),
              if (booked) ...[
                const SizedBox(height: 2),
                const Text(
                  'Booked',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
