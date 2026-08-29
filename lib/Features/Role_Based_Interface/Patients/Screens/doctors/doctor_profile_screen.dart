import 'package:flutter/material.dart';
import 'package:medicus/Features/Appointments/Models/doctor_availability_window.dart';
import 'package:medicus/Features/Appointments/Services/appointment_repository.dart';
import 'package:medicus/Features/Appointments/Services/doctor_availability_repository.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';
import 'package:medicus/Utilities/sizes.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/doctors/doctor_result_card.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/doctors/booked_appointment.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Screens/doctors/appointment_confirmation_screen.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key, required this.doctor, required this.onBooked, required this.appointments});

  final DoctorSummary doctor;
  final ValueChanged<BookedAppointment> onBooked;
  final List<BookedAppointment> appointments;

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  static const DoctorAvailabilityRepository _availabilityRepository = DoctorAvailabilityRepository();
  static const AppointmentRepository _appointmentRepository = AppointmentRepository();

  late final List<DateTime> _dates = List.generate(
    7,
    (i) => DateTime.now().add(Duration(days: i)),
  );

  int _selectedDateIndex = 0;
  DoctorAvailabilityWindow? _selectedWindow;

  bool _loading = true;
  List<DoctorAvailabilityWindow> _windows = [];
  Map<String, int> _bookedCountByWindowId = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final List<DoctorAvailabilityWindow> windows =
          await _availabilityRepository.fetchForDoctor(widget.doctor.doctorId);
      final counts = <String, int>{};
      for (final window in windows) {
        for (final DateTime date in _dates) {
          if (window.weekday != date.weekday) continue;
          final int count = await _appointmentRepository.countBookingsForWindow(
            doctorId: widget.doctor.doctorId,
            windowId: window.id,
            date: date,
          );
          counts['${window.id}_${date.year}${date.month}${date.day}'] = count;
        }
      }
      if (!mounted) return;
      setState(() {
        _windows = windows;
        _bookedCountByWindowId = counts;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  List<DoctorAvailabilityWindow> get _windowsForSelectedDate {
    final DateTime date = _dates[_selectedDateIndex];
    return _windows.where((w) => w.weekday == date.weekday).toList();
  }

  int _bookedCountFor(DoctorAvailabilityWindow window) {
    final DateTime date = _dates[_selectedDateIndex];
    return _bookedCountByWindowId['${window.id}_${date.year}${date.month}${date.day}'] ?? 0;
  }

  void _selectDate(int index) {
    setState(() {
      _selectedDateIndex = index;
      _selectedWindow = null;
    });
  }

  void _selectWindow(DoctorAvailabilityWindow window) {
    setState(() => _selectedWindow = window);
  }

  void _handleBook() {
    if (_selectedWindow == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AppointmentConfirmationScreen(
          doctor: widget.doctor,
          date: _dates[_selectedDateIndex],
          window: _selectedWindow!,
          onConfirmed: widget.onBooked,
          existingAppointments: widget.appointments,
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
    final List<DoctorAvailabilityWindow> windows = _windowsForSelectedDate;

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
                            doctor.experienceYears > 0
                                ? '${doctor.specialty} • ${doctor.experienceYears} yrs exp'
                                : doctor.specialty,
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                          if (doctor.hospital.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              doctor.hospital,
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              if (doctor.rating > 0) ...[
                                const Icon(Icons.star, size: 15, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  doctor.rating.toStringAsFixed(1),
                                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Flexible(
                                child: Text(
                                  doctor.fee > 0 ? '৳${doctor.fee} fee' : 'Fee on request',
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: MColors.primaryColor,
                                  ),
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
                  '${doctor.name} is a ${doctor.specialty.toLowerCase()} specialist'
                  '${doctor.hospital.isNotEmpty ? ' at ${doctor.hospital}' : ''}, '
                  'helping patients with consultations, diagnoses, and ongoing treatment plans.',
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
                const SizedBox(height: 12),
                if (_loading)
                  const Center(child: CircularProgressIndicator(color: MColors.primaryColor))
                else if (windows.isEmpty)
                  Text(
                    "This doctor hasn't set availability for this day yet — try another date.",
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  )
                else
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final DoctorAvailabilityWindow window in windows)
                        _SlotChip(
                          window: window,
                          bookedCount: _bookedCountFor(window),
                          selected: window.id == _selectedWindow?.id,
                          isDark: isDark,
                          onTap: () => _selectWindow(window),
                        ),
                    ],
                  ),
              ],
            ),
            Positioned(
              left: pad,
              right: pad,
              bottom: 16,
              child: ElevatedButton(
                onPressed: _selectedWindow == null ? null : _handleBook,
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
    required this.window,
    required this.bookedCount,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final DoctorAvailabilityWindow window;
  final int bookedCount;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isFull = bookedCount >= window.capacity;

    return Material(
      color: isFull
          ? (isDark ? Colors.white10 : Colors.black12)
          : selected
              ? MColors.primaryColor
              : (isDark ? const Color(0xFF1F1F1F) : Colors.white),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isFull ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                window.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isFull
                      ? Colors.grey
                      : selected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isFull ? 'Full' : '$bookedCount/${window.capacity} booked',
                style: TextStyle(
                  fontSize: 10,
                  color: isFull
                      ? Colors.redAccent
                      : selected
                          ? Colors.white70
                          : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
