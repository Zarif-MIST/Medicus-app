import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';
import 'package:medicus/Utilities/sizes.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/doctors/specialty_filter_chips.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Widgets/LiquidSearchBar.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Widgets/customShapes.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/doctors/doctor_result_card.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/doctors/booked_appointment.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Screens/doctors/doctor_profile_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Utilities/doctor_directory.dart';

class SpecialistSelectionScreen extends StatefulWidget {
  const SpecialistSelectionScreen({
    super.key,
    required this.appointments,
    required this.onBook,
  });

  final List<BookedAppointment> appointments;
  final ValueChanged<BookedAppointment> onBook;

  @override
  State<SpecialistSelectionScreen> createState() =>
      _SpecialistSelectionScreenState();
}

class _SpecialistSelectionScreenState extends State<SpecialistSelectionScreen> {
  static const DoctorDirectoryService _directoryService =
      DoctorDirectoryService();

  Specialty? _selectedSpecialty;
  List<DoctorSummary> _allDoctors = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final List<DoctorSummary> doctors = await _directoryService
          .fetchAllDoctors();
      if (!mounted) return;
      setState(() {
        _allDoctors = doctors;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _handleSpecialtyTap(Specialty specialty) {
    setState(() {
      _selectedSpecialty = _selectedSpecialty?.name == specialty.name
          ? null
          : specialty;
    });
  }

  void _onDoctorSelected(DoctorSummary doctor) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            DoctorProfileScreen(doctor: doctor, onBooked: widget.onBook),
      ),
    );
  }

  List<DoctorSummary> get _visibleDoctors {
    if (_selectedSpecialty == null) {
      return _allDoctors.take(3).toList();
    }
    return _allDoctors
        .where((d) => d.specialty == _selectedSpecialty!.name)
        .toList();
  }

  /// Only appointments today or later, soonest first — a past booking
  /// should drop off this list once its date has gone by, not stick around
  /// forever alongside genuinely upcoming ones.
  List<BookedAppointment> get _upcomingAppointments {
    final DateTime today = DateTime.now();
    final DateTime todayOnly = DateTime(today.year, today.month, today.day);
    final List<BookedAppointment> upcoming =
        widget.appointments
            .where(
              (a) => !DateTime(
                a.date.year,
                a.date.month,
                a.date.day,
              ).isBefore(todayOnly),
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    return upcoming;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);
    final double pad = Sizes.responsivePadding(context);
    final theme = Theme.of(context);
    final List<DoctorSummary> doctors = _visibleDoctors;
    final List<BookedAppointment> upcomingAppointments = _upcomingAppointments;

    return Container(
      color: isDark ? const Color(0xFF181818) : Colors.white,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            ClipPath(
              clipper: MCurvedEdges(),
              child: Container(
                color: MColors.primaryColor,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(pad, pad * 0.8, pad, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Find a Doctor',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose a specialist or search directly',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      SizedBox(height: pad * 0.8),
                      LiquidGlassSearchBar(
                        hintText: 'Search specialist or doctor name',
                        onSubmitted: (_) {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(pad, pad * 0.8, pad, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (upcomingAppointments.isNotEmpty) ...[
                    Text(
                      'Upcoming Appointments',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 14),
                    for (int i = 0; i < upcomingAppointments.length; i++) ...[
                      if (i != 0) const SizedBox(height: 10),
                      _UpcomingAppointmentCard(
                        appointment: upcomingAppointments[i],
                      ),
                    ],
                    SizedBox(height: pad),
                  ],
                  SpecialtyFilterChips(
                    specialties: kSpecialties,
                    selected: _selectedSpecialty,
                    onSelected: _handleSpecialtyTap,
                  ),
                  SizedBox(height: pad * 0.5),
                  Text(
                    _selectedSpecialty == null
                        ? 'Top Doctors'
                        : '${_selectedSpecialty!.name} Specialists',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 14),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: MColors.primaryColor,
                        ),
                      ),
                    )
                  else if (doctors.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        _selectedSpecialty == null
                            ? 'No doctors have registered on Medicus yet.'
                            : 'No doctors found for this specialty yet.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    )
                  else
                    for (int i = 0; i < doctors.length; i++) ...[
                      if (i != 0) const SizedBox(height: 10),
                      DoctorResultCard(
                        doctor: doctors[i],
                        onTap: () => _onDoctorSelected(doctors[i]),
                      ),
                    ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

class _UpcomingAppointmentCard extends StatelessWidget {
  const _UpcomingAppointmentCard({required this.appointment});

  final BookedAppointment appointment;

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);
    final theme = Theme.of(context);
    final DateTime date = appointment.date;
    final String formattedDate =
        '${_weekdays[date.weekday - 1]}, ${date.day} ${_months[date.month - 1]}';

    return LiquidGlassLayer(
      settings: LiquidGlassSettings(
        thickness: 16,
        blur: 10,
        glassColor: isDark ? const Color(0x22FFFFFF) : const Color(0x92FFFFFF),
        lightIntensity: 1.05,
        saturation: 1.15,
        refractiveIndex: 1.25,
      ),
      fake: true,
      child: LiquidGlass(
        shape: LiquidRoundedSuperellipse(borderRadius: 16),
        child: Material(
          color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: MColors.primaryColor.withValues(alpha: 0.12),
                  child: const Icon(
                    Icons.event_available,
                    color: MColors.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.doctorName,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        appointment.specialty,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formattedDate,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      appointment.time,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
