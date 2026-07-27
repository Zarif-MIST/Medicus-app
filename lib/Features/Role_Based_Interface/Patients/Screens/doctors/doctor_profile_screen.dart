import 'package:flutter/material.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';
import 'package:medicus/Utilities/sizes.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/doctors/doctor_result_card.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/doctors/booked_appointment.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Screens/doctors/appointment_confirmation_screen.dart';

// Mock slots — same options every day until real availability is wired up.
const List<String> _mockTimeSlots = [
  '9:00 AM',
  '10:00 AM',
  '11:00 AM',
  '2:00 PM',
  '4:00 PM',
  '6:00 PM',
];

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key, required this.doctor, required this.onBooked});

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

  int _selectedDateIndex = 0;
  String? _selectedSlot;

  void _selectDate(int index) {
    setState(() {
      _selectedDateIndex = index;
      _selectedSlot = null;
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
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final slot in _mockTimeSlots)
                      _SlotChip(
                        label: slot,
                        selected: slot == _selectedSlot,
                        isDark: isDark,
                        onTap: () => _selectSlot(slot),
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
  const _SlotChip({required this.label, required this.selected, required this.isDark, required this.onTap});

  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? MColors.primaryColor : (isDark ? const Color(0xFF1F1F1F) : Colors.white),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
            ),
          ),
        ),
      ),
    );
  }
}
